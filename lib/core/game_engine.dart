import 'dart:collection';
import 'dart:math';

import 'board.dart';
import 'board_factory.dart';
import 'gravity.dart';
import 'level.dart';
import 'match_finder.dart';
import 'move_finder.dart';
import 'piece.dart';
import 'pos.dart';
import 'steps.dart';

export 'steps.dart' show GameStatus;

part 'game_engine_clear.dart';
part 'game_engine_hazards.dart';
part 'game_engine_specials.dart';

/// A cat on the board. It sits over a cell (pieces fall through underneath)
/// and prowls one step per turn unless it was startled.
class Cat {
  Cat(this.id, this.pos, this.hp);
  final int id;
  Pos pos;
  int hp;
}

class GoalProgress {
  const GoalProgress(this.goal, this.current);
  final LevelGoal goal;
  final int current;
  bool get done => current >= goal.count;
}

/// Pure-Dart rules engine. Nothing in lib/core may import Flutter or Flame.
///
/// One call to [trySwap] resolves the whole turn synchronously and returns
/// the list of [BoardStep]s for the view to animate.
class GameEngine {
  GameEngine(this.level, {int? seed})
      : board = Board(level.rows, level.cols, level.playable),
        rng = Random(seed ?? level.seed),
        _nori = List.of(level.nori),
        _bags = level.bags.isEmpty
            ? List.filled(level.rows * level.cols, 0)
            : List.of(level.bags),
        _mats = level.mats.isEmpty
            ? List.filled(level.rows * level.cols, false)
            : List.of(level.mats),
        _scared = {},
        _cats = [
          for (var i = 0; i < level.cats.length; i++)
            Cat(i, Pos(level.cats[i].row, level.cats[i].col), level.cats[i].hp),
        ],
        _ingredientTotal = level.goals
            .where((g) => g.type == GoalType.deliver)
            .fold(0, (n, g) => n + g.count),
        movesLeft = level.moves {
    board.lockedRows = {for (final c in level.conveyors) c.row};
    for (var i = 0; i < level.locks.length; i++) {
      final kind = level.locks[i];
      if (kind == null) continue;
      final at = _posOf(i);
      _lockKinds[at] = kind;
      board.lockedCells.add(at);
    }
    BoardFactory.fillInitial(board, level.pieces, rng, _makePiece,
        iceAt: (p) => level.ice.isEmpty ? 0 : level.ice[_idx(p)]);
    _placeIngredients();
    for (var i = 0; i < level.fire.length; i++) {
      if (level.fire[i]) board[_posOf(i)]!.burning = true;
    }
    for (var i = 0; i < level.timers.length; i++) {
      if (level.timers[i] > 0) board[_posOf(i)]!.timer = level.timers[i];
    }
  }

  /// Copies the lasting state. The per-turn flags (`_matBroken`, `_fireOut`,
  /// `_bombed`, `_aftershocks`, `_credit`) are reset within every turn, so a
  /// fork taken between turns starts them at their defaults. A new lasting
  /// field must be copied here too.
  GameEngine._fork(GameEngine o, int seed)
      : level = o.level,
        board = o.board.copy(),
        rng = Random(seed),
        _nori = List.of(o._nori),
        _bags = List.of(o._bags),
        _mats = List.of(o._mats),
        _cats = [for (final c in o._cats) Cat(c.id, c.pos, c.hp)],
        _scared = Set.of(o._scared),
        _ingredientTotal = o._ingredientTotal,
        _delivered = o._delivered,
        _spawned = o._spawned,
        _active = o._active,
        movesLeft = o.movesLeft,
        score = o.score,
        status = o.status,
        _nextId = o._nextId {
    _collected.addAll(o._collected);
    _lockKinds.addAll(o._lockKinds);
    _unlocked.addAll(o._unlocked);
  }

  /// Independent copy of the current state for bots and solvers to try a
  /// move on. Refills in the copy use a new RNG seeded with [seed], so the
  /// copy's future differs from the original's.
  GameEngine fork(int seed) => GameEngine._fork(this, seed);

  static const _pointsPerPiece = 20;

  final LevelConfig level;
  final Board board;
  final Random rng;
  int movesLeft;
  int score = 0;
  GameStatus status = GameStatus.playing;

  final List<int> _nori;

  /// Rice bag layers per cell; a bagged cell blocks gravity until it breaks.
  final List<int> _bags;

  /// Which blocked cells are bamboo mats (they spread, bags do not).
  final List<bool> _mats;

  /// Set when a clear breaks a mat; a turn without one lets the mats spread.
  bool _matBroken = false;

  final List<Cat> _cats;

  /// Key locks by cell and the colours already matched to open them.
  final Map<Pos, PieceKind> _lockKinds = {};
  final Set<PieceKind> _unlocked = {};

  /// Set when a bomb ran out this turn.
  bool _bombed = false;

  /// Cats startled this turn; they stay put instead of prowling.
  final Set<int> _scared;

  /// Set when a clear puts out a burning piece; otherwise fire spreads.
  bool _fireOut = false;

  final int _ingredientTotal;
  int _delivered = 0;
  int _spawned = 0;

  /// Ingredients currently on the board.
  int _active = 0;
  int _nextId = 0;

  /// Origins of Wasabi Bombs that still owe their second blast.
  final List<Pos> _aftershocks = [];

  /// False while a conveyor shift's own cascade resolves (see [_endTurn]).
  bool _credit = true;
  final Map<PieceKind, int> _collected = {};

  /// Pieces of [kind] cleared so far (feeds the weekly event tally).
  int collectedOf(PieceKind kind) => _collected[kind] ?? 0;

  int _currentFor(LevelGoal g) => switch (g.type) {
        GoalType.collect => _collected[g.piece] ?? 0,
        GoalType.score => score,
        GoalType.clearNori => g.count - _nori.where((n) => n > 0).length,
        GoalType.breakIce => g.count - _frozenCount,
        GoalType.breakBag => g.count - _bagCount,
        GoalType.deliver => _delivered,
        GoalType.clearMats => g.count - _matCount,
        GoalType.putOut => g.count - _burningCount,
        GoalType.shooCats => g.count - _cats.length,
      };

  List<GoalProgress> get goals => [
        for (final g in level.goals) GoalProgress(g, _currentFor(g)),
      ];

  int get stars => status != GameStatus.won
      ? 0
      : max(1, level.stars.where((s) => score >= s).length);

  /// Whether every goal is met. Cheaper than building [goals] each time.
  bool get _allGoalsDone => level.goals.every((g) => _currentFor(g) >= g.count);

  int get _frozenCount {
    var n = 0;
    for (final p in board.positions) {
      if (board[p]?.frozen ?? false) n++;
    }
    return n;
  }

  int get _burningCount {
    var n = 0;
    for (final p in board.positions) {
      if (board[p]?.burning ?? false) n++;
    }
    return n;
  }

  /// Cats still prowling; the view reads this once at the start.
  List<Cat> get cats => List.unmodifiable(_cats);

  int get _matCount => _mats.where((m) => m).length;

  int get _bagCount {
    var n = 0;
    for (var i = 0; i < _bags.length; i++) {
      if (_bags[i] > 0 && !_mats[i]) n++;
    }
    return n;
  }

  /// Index of [p] in the per-cell lists (`_nori`, `_bags`, `_mats`).
  int _idx(Pos p) => p.row * board.cols + p.col;

  Pos _posOf(int i) => Pos(i ~/ board.cols, i % board.cols);

  /// Whether a bamboo mat covers [p].
  bool matAt(Pos p) => board.inBounds(p) && _mats[_idx(p)];

  /// Rice bag layers currently in [p] (0 when none).
  int bagAt(Pos p) => board.inBounds(p) ? _bags[_idx(p)] : 0;

  /// Nori layers currently under [p] (0 when none).
  int noriAt(Pos p) => board.inBounds(p) ? _nori[_idx(p)] : 0;

  /// Kinds a collect goal still needs; cats and the Soy Fish go for these.
  Set<PieceKind?> get _wantedKinds => {
        for (final g in level.goals)
          if (g.type == GoalType.collect && _currentFor(g) < g.count) g.piece,
      };

  // ---------------------------------------------------------------- turn --

  List<BoardStep> trySwap(Pos a, Pos b) {
    if (status != GameStatus.playing ||
        !a.isAdjacentTo(b) ||
        !board.isPlayable(a) ||
        !board.isPlayable(b)) {
      return const [];
    }
    final pa = board[a], pb = board[b];
    if (pa == null || pb == null) return const [];
    // Conveyor rows are locked: the belt moves them, the player cannot.
    if (board.isLocked(a) || board.isLocked(b)) return [InvalidSwapStep(a, b)];
    // Iced pieces stay put until the ice is cracked.
    if (pa.frozen || pb.frozen) return [InvalidSwapStep(a, b)];

    final specialSwap =
        pa.isOmakase || pb.isOmakase || (pa.isSpecial && pb.isSpecial);
    // An Omakase has no kind to pair with an ingredient.
    if (specialSwap && (pa.ingredient || pb.ingredient)) {
      return [InvalidSwapStep(a, b)];
    }
    final steps = <BoardStep>[];
    _aftershocks.clear();
    board.swap(a, b);

    if (specialSwap) {
      steps
        ..add(SwapStep(a, b))
        ..addAll(_resolveSpecialSwap(a, b))
        ..addAll(_settleAndCascade(startAt: 2));
    } else {
      final groups = MatchFinder.find(board, preferred: {a, b});
      if (groups.isEmpty) {
        board.swap(a, b);
        return [InvalidSwapStep(a, b)];
      }
      steps
        ..add(SwapStep(a, b))
        ..addAll(_cascade(groups, startAt: 1));
    }
    steps.addAll(_endTurn());
    return steps;
  }

  // ------------------------------------------------------------ boosters --

  /// Chopsticks: destroy one piece. Costs no move.
  List<BoardStep> useChopsticks(Pos p) {
    if (status != GameStatus.playing ||
        board[p] == null ||
        board[p]!.ingredient) {
      return const [];
    }
    _aftershocks.clear();
    return [
      ..._clear(seed: {p}, cascade: 1),
      ..._settleAndCascade(startAt: 2),
      ..._endTurn(spendMove: false),
    ];
  }

  /// Free swap: swap any two pieces, matching or not. Costs no move.
  List<BoardStep> useFreeSwap(Pos a, Pos b) {
    if (status != GameStatus.playing ||
        a == b ||
        board[a] == null ||
        board[b] == null ||
        board[a]!.frozen ||
        board[b]!.frozen) {
      return const [];
    }
    _aftershocks.clear();
    board.swap(a, b);
    return [
      SwapStep(a, b),
      ..._cascade(MatchFinder.find(board, preferred: {a, b}), startAt: 1),
      ..._endTurn(spendMove: false),
    ];
  }

  /// Shuffle booster: reshuffle the whole board. Costs no move.
  List<BoardStep> useShuffle() {
    if (status != GameStatus.playing) return const [];
    return [
      ShuffleStep(BoardFactory.shuffle(board, rng)),
      TurnEndStep(movesLeft: movesLeft, score: score, status: status),
    ];
  }

  /// Starter booster: turns one random plain piece into [type] before the
  /// first move. Returns false when no piece qualifies.
  bool placeStarter(SpecialType type) {
    final cells = [
      for (final p in board.positions)
        if (board[p] case final piece?
            when !piece.isSpecial &&
                !piece.ingredient &&
                !piece.frozen &&
                !piece.burning &&
                piece.timer == 0 &&
                !board.lockedCells.contains(p))
          p
    ];
    if (cells.isEmpty) return false;
    board[cells[rng.nextInt(cells.length)]]!.special = type;
    return true;
  }

  /// Extra moves; also revives a level that was just lost.
  void addMoves(int n) {
    if (status == GameStatus.won) return;
    movesLeft += n;
    if (status == GameStatus.lost && movesLeft > 0) status = GameStatus.playing;
  }

  List<BoardStep> _cascade(List<MatchGroup> groups, {required int startAt}) {
    final steps = <BoardStep>[];
    var depth = startAt;
    while (depth < 200) {
      if (_aftershocks.isNotEmpty) {
        // Wasabi blasts a second time once the board has settled.
        final o = _aftershocks.removeAt(0);
        final area = _square(o, 1);
        steps
          ..addAll(_clear(
            seed: area,
            cascade: depth,
            pre: [SpecialActivateStep(SpecialType.wasabi, o, area)],
          ))
          ..addAll(_gravityAndRefill());
        depth++;
        groups = MatchFinder.find(board);
        continue;
      }
      if (groups.isEmpty) break;
      steps
        ..addAll(_clear(
          seed: {for (final g in groups) ...g.cells},
          spawns: groups,
          cascade: depth,
        ))
        ..addAll(_gravityAndRefill());
      depth++;
      groups = MatchFinder.find(board);
    }
    return steps;
  }

  /// Settles the board, then resolves whatever matches that made.
  List<BoardStep> _settleAndCascade({required int startAt}) => [
        ..._gravityAndRefill(),
        ..._cascade(MatchFinder.find(board), startAt: startAt),
      ];

  List<BoardStep> _endTurn({bool spendMove = true}) {
    final shifted = <BoardStep>[];
    if (spendMove && !_allGoalsDone) {
      shifted.addAll(_runConveyors());
      // Pieces the belt matches by itself are spoiled: they clear, but earn
      // no score or goal progress. The player must plan the shift, not
      // lean on it for free cascades.
      _credit = false;
      shifted.addAll(_cascade(MatchFinder.find(board), startAt: 1));
      _credit = true;
      // Each hazard acts in turn and stops once the order is complete.
      for (final hazard in [_prowlCats, _spreadFire, _spreadMats, _tickBombs]) {
        if (_allGoalsDone) break;
        shifted.addAll(hazard());
      }
    }
    _matBroken = false;
    _fireOut = false;
    _scared.clear();
    if (spendMove) movesLeft--;
    final won = _allGoalsDone;
    if (won) {
      status = GameStatus.won;
    } else if (movesLeft <= 0 || _bombed) {
      status = GameStatus.lost;
    }
    _bombed = false;
    return [
      ...shifted,
      if (won) ..._bonusRound(),
      if (status == GameStatus.playing && MoveFinder.findMove(board) == null)
        ShuffleStep(BoardFactory.shuffle(board, rng)),
      TurnEndStep(movesLeft: movesLeft, score: score, status: status),
    ];
  }

  /// Slides every conveyor row one cell along its playable cells, wrapping
  /// the last piece round. Returns nothing when no piece moved.
  List<BoardStep> _runConveyors() {
    final steps = <BoardStep>[];
    for (final c in level.conveyors) {
      final cells = [
        for (var col = 0; col < board.cols; col++)
          if (board.isPlayable(Pos(c.row, col))) Pos(c.row, col),
      ];
      if (cells.length < 2) continue;
      final pieces = [for (final p in cells) board[p]];
      if (pieces.any((p) => p == null)) continue;
      final moves = <FallMove>[];
      for (var i = 0; i < cells.length; i++) {
        final to = cells[(i + c.dir + cells.length) % cells.length];
        board[to] = pieces[i];
        moves.add(FallMove(pieces[i]!.id, cells[i], to));
      }
      steps.add(ConveyorStep(moves));
    }
    return steps;
  }

  /// Turns each leftover move into a random Knife/Wasabi on a plain piece,
  /// then sets them all off for extra score (and so extra stars).
  List<BoardStep> _bonusRound() {
    final plain = [
      for (final p in board.positions)
        if (board[p] != null &&
            !board[p]!.isSpecial &&
            !board[p]!.frozen &&
            !board[p]!.ingredient)
          p,
    ]..shuffle(rng);
    final picked = plain.take(max(0, movesLeft)).toList();
    movesLeft = 0;
    if (picked.isEmpty) return const [];

    const types = [
      SpecialType.knifeRow,
      SpecialType.knifeCol,
      SpecialType.wasabi,
    ];
    final changes = <int, SpecialType>{};
    for (final p in picked) {
      final t = types[rng.nextInt(types.length)];
      board[p]!.special = t;
      changes[board[p]!.id] = t;
    }
    return [
      TransformStep(changes),
      ..._clear(seed: picked.toSet(), cascade: 1),
      ..._settleAndCascade(startAt: 2),
    ];
  }

  // ------------------------------------------------------ gravity/refill --

  late final _gravity = GravitySettler(board, level.gravity, level.portals, rng,
      isBlocked: (p) => bagAt(p) > 0,
      newPiece: () => _spawnIngredient()
          ? _makeIngredient()
          : _makePiece(level.pieces[rng.nextInt(level.pieces.length)]));

  /// Settles the board; ingredients that land on the bottom row leave, and
  /// the gap they leave settles again.
  List<BoardStep> _gravityAndRefill() {
    final steps = <BoardStep>[];
    for (var i = 0; i < 20; i++) {
      steps.addAll(_gravity.settle());
      final gone = _deliverReached();
      if (gone.isEmpty) break;
      steps.add(DeliverStep(gone));
    }
    return steps;
  }

  /// Removes ingredients standing on the last open cell of their line.
  List<ClearedPiece> _deliverReached() {
    final gone = <ClearedPiece>[];
    for (var line = 0; line < _gravity.lineCount; line++) {
      for (var k = _gravity.lineLength - 1; k >= 0; k--) {
        final p = _gravity.lineCell(line, k);
        if (!board.isPlayable(p)) continue;
        final piece = board[p];
        if (piece != null && piece.ingredient) {
          gone.add(ClearedPiece(piece.id, p));
          board[p] = null;
          _delivered++;
          _active--;
          score += _deliverPoints;
        }
        break;
      }
    }
    return gone;
  }

  static const _deliverPoints = 150;

  // ------------------------------------------------------------- helpers --

  Piece _makePiece(PieceKind k) => Piece(id: _nextId++, kind: k);

  Piece _makeIngredient() {
    _spawned++;
    _active++;
    return Piece(id: _nextId++, kind: null, ingredient: true);
  }

  static const _maxActiveIngredients = 3;

  /// Whether the next piece fed in from the top is an ingredient. Only
  /// delivery levels draw from the RNG here, so other levels are unchanged.
  bool _spawnIngredient() =>
      _spawned < _ingredientTotal &&
      _active < _maxActiveIngredients &&
      rng.nextDouble() < 0.35;

  /// Drops the first ingredients into random columns, somewhere in the upper
  /// half so the first deliveries come quickly.
  void _placeIngredients() {
    if (_ingredientTotal == 0) return;
    final columns = [
      for (var line = 0; line < _gravity.lineCount; line++)
        [
          for (var k = 0; k < _gravity.lineLength; k++)
            if (board.isPlayable(_gravity.lineCell(line, k)))
              _gravity.lineCell(line, k),
        ],
    ].where((cells) => cells.length >= 3).toList()
      ..shuffle(rng);
    final n = min(_ingredientTotal, _maxActiveIngredients);
    for (final cells in columns.take(n)) {
      board[cells[rng.nextInt((cells.length + 1) ~/ 2)]] = _makeIngredient();
    }
    if (MoveFinder.findMove(board) == null) BoardFactory.shuffle(board, rng);
  }
}
