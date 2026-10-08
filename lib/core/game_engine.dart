import 'dart:collection';
import 'dart:math';

import 'board.dart';
import 'board_factory.dart';
import 'level.dart';
import 'match_finder.dart';
import 'move_finder.dart';
import 'piece.dart';
import 'pos.dart';
import 'steps.dart';

export 'steps.dart' show GameStatus;

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
      final at = Pos(i ~/ level.cols, i % level.cols);
      _lockKinds[at] = kind;
      board.lockedCells.add(at);
    }
    BoardFactory.fillInitial(board, level.pieces, rng, _makePiece,
        iceAt: (p) =>
            level.ice.isEmpty ? 0 : level.ice[p.row * level.cols + p.col]);
    _placeIngredients();
    for (var i = 0; i < level.fire.length; i++) {
      if (level.fire[i]) {
        board[Pos(i ~/ level.cols, i % level.cols)]!.burning = true;
      }
    }
    for (var i = 0; i < level.timers.length; i++) {
      if (level.timers[i] > 0) {
        board[Pos(i ~/ level.cols, i % level.cols)]!.timer = level.timers[i];
      }
    }
  }

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
  bool get _allGoalsDone =>
      level.goals.every((g) => _currentFor(g) >= g.count);

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

  int get _bagCount => [
        for (var i = 0; i < _bags.length; i++)
          if (_bags[i] > 0 && !_mats[i]) i,
      ].length;

  /// Whether a bamboo mat covers [p].
  bool matAt(Pos p) => board.inBounds(p) && _mats[p.row * board.cols + p.col];

  /// Rice bag layers currently in [p] (0 when none).
  int bagAt(Pos p) => board.inBounds(p) ? _bags[p.row * board.cols + p.col] : 0;

  /// Nori layers currently under [p] (0 when none).
  int noriAt(Pos p) =>
      board.inBounds(p) ? _nori[p.row * board.cols + p.col] : 0;

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
        ..addAll(_gravityAndRefill())
        ..addAll(_cascade(MatchFinder.find(board), startAt: 2));
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
      ..._gravityAndRefill(),
      ..._cascade(MatchFinder.find(board), startAt: 2),
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
      if (!_allGoalsDone) shifted.addAll(_prowlCats());
      if (!_fireOut && !_allGoalsDone) {
        shifted.addAll(_spreadFire());
      }
      if (!_matBroken && !_allGoalsDone) {
        shifted.addAll(_spreadMats());
      }
      if (!_allGoalsDone) shifted.addAll(_tickBombs());
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
      ..._gravityAndRefill(),
      ..._cascade(MatchFinder.find(board), startAt: 2),
    ];
  }

  // --------------------------------------------------------------- clear --

  /// Clears [seed], chain-activating any specials hit along the way.
  /// [consumed] cells are cleared but their special does NOT auto-fire
  /// (used when two specials were swapped and already produced a combo).
  List<BoardStep> _clear({
    required Set<Pos> seed,
    required int cascade,
    List<MatchGroup> spawns = const [],
    Set<Pos> consumed = const {},
    List<BoardStep> pre = const [],
  }) {
    final steps = <BoardStep>[...pre];
    final cleared = <Pos>{};
    final activated = <Pos>{...consumed};
    final queue = Queue<Pos>();
    // Iced pieces hit by a blast or touched by a clear lose one layer.
    final cracked = <Pos>{};

    void mark(Pos p) {
      final piece = board[p];
      if (piece == null || piece.ingredient) return;
      if (piece.frozen) {
        cracked.add(p);
        return;
      }
      if (!cleared.add(p)) return;
      if (piece.isSpecial && !activated.contains(p)) queue.add(p);
    }

    seed.forEach(mark);
    while (queue.isNotEmpty) {
      final p = queue.removeFirst();
      if (!activated.add(p)) continue;
      final type = board[p]!.special!;
      if (type == SpecialType.wasabi) _aftershocks.add(p);
      final area = _areaOf(type, p, avoid: cleared);
      steps.add(SpecialActivateStep(type, p, area));
      area.forEach(mark);
    }

    for (final p in cleared) {
      for (final d in const [Pos(0, 1), Pos(0, -1), Pos(1, 0), Pos(-1, 0)]) {
        final q = p + d;
        if (board[q]?.frozen ?? false) cracked.add(q);
      }
    }

    final cracks = <Pos>{};
    for (final p in cleared) {
      for (final d in const [Pos(0, 1), Pos(0, -1), Pos(1, 0), Pos(-1, 0)]) {
        if (bagAt(p + d) > 0) cracks.add(p + d);
      }
    }

    final startled = <CatHit>[];
    for (final cat in _cats) {
      final near = cleared.contains(cat.pos) ||
          [
            for (final d in const [
              Pos(0, 1),
              Pos(0, -1),
              Pos(1, 0),
              Pos(-1, 0)
            ])
              cat.pos + d,
          ].any(cleared.contains);
      if (!near) continue;
      cat.hp--;
      _scared.add(cat.id);
      startled.add(CatHit(cat.id, cat.pos, cat.hp));
    }
    _cats.removeWhere((c) => c.hp <= 0);

    final removed = <ClearedPiece>[];
    final opened = <PieceKind>{};
    for (final p in cleared) {
      final piece = board[p]!;
      if (piece.burning) _fireOut = true;
      final k = piece.kind;
      if (k != null && _credit) {
        _collected[k] = (_collected[k] ?? 0) + 1;
        if (_lockKinds.containsValue(k)) opened.add(k);
      }
      removed.add(ClearedPiece(piece.id, p));
      board[p] = null;
    }

    final created = <SpawnedPiece>[];
    for (final g in spawns) {
      final type = g.spawn, at = g.spawnAt;
      if (type == null || at == null) continue;
      final piece = Piece(
        id: _nextId++,
        kind: type == SpecialType.omakase ? null : g.kind,
        special: type,
      );
      board[at] = piece;
      created.add(SpawnedPiece(PieceSnapshot.of(piece), at));
    }

    final gained = _credit ? removed.length * _pointsPerPiece * cascade : 0;
    score += gained;
    steps.add(ClearStep(removed, created, gained, cascade));

    final noriLeft = <Pos, int>{};
    for (final p in cleared) {
      final i = p.row * board.cols + p.col;
      if (_nori[i] > 0) noriLeft[p] = --_nori[i];
    }
    if (noriLeft.isNotEmpty) steps.add(NoriStep(noriLeft));

    if (startled.isNotEmpty) steps.add(CatHitStep(startled));

    // Matching a lock's colour opens every lock of that colour for good.
    for (final kind in opened) {
      if (!_unlocked.add(kind)) continue;
      final cells = [
        for (final e in _lockKinds.entries)
          if (e.value == kind) e.key,
      ];
      board.lockedCells.removeAll(cells);
      steps.add(UnlockStep(cells, kind));
    }

    if (cracks.isNotEmpty) {
      final hits = <BagHit>[];
      for (final q in cracks) {
        final i = q.row * board.cols + q.col;
        final left = --_bags[i];
        final mat = _mats[i];
        if (left == 0) {
          board.openCell(q);
          if (mat) {
            _mats[i] = false;
            _matBroken = true;
          }
        }
        hits.add(BagHit(q, left, mat: mat));
      }
      steps.add(BagStep(hits));
    }

    if (cracked.isNotEmpty) {
      steps.add(IceStep([
        for (final p in cracked) IceHit(board[p]!.id, p, --board[p]!.ice),
      ]));
    }
    return steps;
  }

  /// Cells a single special hits when it fires at [o].
  Set<Pos> _areaOf(SpecialType type, Pos o, {Set<Pos> avoid = const {}}) {
    switch (type) {
      case SpecialType.knifeRow:
        return _row(o.row);
      case SpecialType.knifeCol:
        return _col(o.col);
      case SpecialType.wasabi:
        // First 3×3 blast; the second one runs from _cascade (_aftershocks).
        return _square(o, 1);
      case SpecialType.omakase:
        // Hit by another special: clear a random kind still on the board.
        final kinds = <PieceKind>{
          for (final p in board.positions)
            if (!avoid.contains(p) && board[p]?.kind != null) board[p]!.kind!,
        };
        if (kinds.isEmpty) return {o};
        return {o, ..._ofKind(kinds.elementAt(rng.nextInt(kinds.length)))};
      case SpecialType.soyFish:
        final target = _fishTarget(avoid: {...avoid, o});
        return {o, if (target != null) target};
    }
  }

  List<BoardStep> _resolveSpecialSwap(Pos a, Pos b) {
    // After the swap the piece the player moved sits on [b].
    final pa = board[a]!, pb = board[b]!;

    // ---- Omakase involved ----
    final o = pb.isOmakase ? b : (pa.isOmakase ? a : null);
    if (o != null) {
      final x = o == a ? b : a;
      final other = board[x]!;
      if (other.isOmakase) {
        final all = {
          for (final p in board.positions)
            if (board[p] != null) p
        };
        return _clear(
          seed: all,
          consumed: {a, b},
          cascade: 1,
          pre: [
            SpecialActivateStep(SpecialType.omakase, o, all,
                comboWith: SpecialType.omakase),
          ],
        );
      }
      final targets = _ofKind(other.kind!)..add(x);
      final upgrade = other.special;
      final pre = <BoardStep>[
        SpecialActivateStep(SpecialType.omakase, o, {o, ...targets},
            comboWith: upgrade),
      ];
      if (upgrade != null) {
        final changes = <int, SpecialType>{};
        for (final p in targets) {
          final piece = board[p]!;
          if (piece.isSpecial) continue;
          final t = upgrade.isKnife
              ? (rng.nextBool() ? SpecialType.knifeRow : SpecialType.knifeCol)
              : upgrade;
          piece.special = t;
          changes[piece.id] = t;
        }
        pre.add(TransformStep(changes));
      }
      return _clear(seed: {o, ...targets}, consumed: {o}, pre: pre, cascade: 1);
    }

    // ---- Two non-Omakase specials ----
    final ta = pa.special!, tb = pb.special!;
    final area = <Pos>{a, b};
    if (ta == SpecialType.soyFish || tb == SpecialType.soyFish) {
      // The fish carries the other special to its target.
      final carried = ta == SpecialType.soyFish ? tb : ta;
      final target = _fishTarget(avoid: {a, b});
      if (target != null) {
        area.addAll(carried == SpecialType.soyFish
            ? {target}
            : _areaOf(carried, target, avoid: {a, b}));
      }
    } else if (ta.isKnife && tb.isKnife) {
      area
        ..addAll(_row(b.row))
        ..addAll(_col(b.col));
    } else if (ta == SpecialType.wasabi && tb == SpecialType.wasabi) {
      area.addAll(_square(b, 2));
    } else {
      // Knife + Wasabi: 3 rows and 3 columns.
      for (var d = -1; d <= 1; d++) {
        area
          ..addAll(_row(b.row + d))
          ..addAll(_col(b.col + d));
      }
    }
    return _clear(
      seed: area,
      consumed: {a, b},
      cascade: 1,
      pre: [SpecialActivateStep(tb, b, area, comboWith: ta)],
    );
  }

  // ------------------------------------------------------ gravity/refill --

  /// Settles the board; ingredients that land on the bottom row leave, and
  /// the gap they leave settles again.
  List<BoardStep> _gravityAndRefill() {
    final steps = <BoardStep>[];
    for (var i = 0; i < 20; i++) {
      steps.addAll(_settle());
      final gone = _deliverReached();
      if (gone.isEmpty) break;
      steps.add(DeliverStep(gone));
    }
    return steps;
  }

  // Gravity runs along "lines": columns for up/down, rows for left/right.
  // Cells are indexed upstream (where new pieces enter) to downstream.

  int get _lineCount => level.gravity.vertical ? board.cols : board.rows;

  int get _lineLength => level.gravity.vertical ? board.rows : board.cols;

  Pos get _step => Pos(level.gravity.dr, level.gravity.dc);

  Pos _lineCell(int line, int k) => switch (level.gravity) {
        Gravity.down => Pos(k, line),
        Gravity.up => Pos(board.rows - 1 - k, line),
        Gravity.right => Pos(line, k),
        Gravity.left => Pos(line, board.cols - 1 - k),
      };

  /// Removes ingredients standing on the last open cell of their line.
  List<ClearedPiece> _deliverReached() {
    final gone = <ClearedPiece>[];
    for (var line = 0; line < _lineCount; line++) {
      for (var k = _lineLength - 1; k >= 0; k--) {
        final p = _lineCell(line, k);
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

  List<BoardStep> _settle() {
    final before = <int, Pos>{
      for (final p in board.positions)
        if (board[p] != null) board[p]!.id: p,
    };
    final fresh = <int, (PieceSnapshot, Pos)>{};
    final step = _step;
    // A line splits into segments at rice bags (void cells stay transparent
    // to falling pieces, bags do not). Only the first segment is fed from
    // upstream; the others fill by pieces sliding in diagonally.
    final segments = <List<Pos>>[];
    final fed = <bool>[];
    for (var line = 0; line < _lineCount; line++) {
      var current = <Pos>[];
      var sealed = false;
      void close() {
        if (current.isNotEmpty) {
          segments.add(current);
          fed.add(!sealed);
          sealed = true;
        }
        current = <Pos>[];
      }

      for (var k = 0; k < _lineLength; k++) {
        final p = _lineCell(line, k);
        if (bagAt(p) > 0) {
          close();
          sealed = true;
        } else if (board.isPlayable(p)) {
          current.add(p);
        }
      }
      close();
    }

    // Portals: the piece resting at the end of the segment above an entry
    // reappears at the top of the exit's segment whenever that has room. The
    // exit segment is fed by the portal instead of from upstream.
    final transfers = <(int, int)>[];
    final portalFed = <int>{};
    for (final portal in level.portals) {
      final into = segments.indexWhere((c) => c.last + step == portal.entry);
      final out = segments.indexWhere((c) => c.first == portal.exit);
      if (into < 0 || out < 0) continue;
      transfers.add((into, out));
      fed[out] = false;
      portalFed.add(out);
    }

    final perp = Pos(step.col.abs(), step.row.abs());
    for (var round = 0; round < 100; round++) {
      for (var s = 0; s < segments.length; s++) {
        final cells = segments[s];
        final stack = [
          for (final p in cells)
            if (board[p] != null) board[p]!,
        ];
        for (final p in cells) {
          board[p] = null;
        }
        var w = cells.length - 1;
        for (var i = stack.length - 1; i >= 0; i--, w--) {
          board[cells[w]] = stack[i];
        }
        if (!fed[s]) continue;
        final missing = w + 1;
        final first = cells.first;
        for (var i = 0; i < missing; i++) {
          final piece = _spawnIngredient()
              ? _makeIngredient()
              : _makePiece(level.pieces[rng.nextInt(level.pieces.length)]);
          board[cells[i]] = piece;
          final back = missing - i;
          fresh[piece.id] = (
            PieceSnapshot.of(piece),
            Pos(first.row - step.row * back, first.col - step.col * back),
          );
        }
      }
      var moved = false;
      for (final (into, out) in transfers) {
        final from = segments[into].last, to = segments[out].first;
        if (board[from] != null && board[to] == null) {
          board[to] = board[from];
          board[from] = null;
          moved = true;
        }
      }
      // Sealed segments whose first cell is empty pull a piece in from the
      // neighbouring line, one cell upstream.
      for (var s = 0; s < segments.length; s++) {
        if (fed[s] || portalFed.contains(s)) continue;
        final top = segments[s].first;
        if (board[top] != null) continue;
        final up = top - step;
        final donors = [
          for (final d in [perp, Pos(-perp.row, -perp.col)])
            if (board[up + d] != null) up + d,
        ];
        if (donors.isEmpty) continue;
        final from = donors[rng.nextInt(donors.length)];
        board[top] = board[from];
        board[from] = null;
        moved = true;
      }
      if (!moved) break;
    }

    final falls = <FallMove>[];
    final refills = <RefillPiece>[];
    for (final p in board.positions) {
      final piece = board[p];
      if (piece == null) continue;
      final f = fresh[piece.id];
      if (f != null) {
        refills.add(RefillPiece(f.$1, p, f.$2));
      } else if (before[piece.id] != p) {
        falls.add(FallMove(piece.id, before[piece.id]!, p));
      }
    }
    return [
      if (falls.isNotEmpty) FallStep(falls),
      if (refills.isNotEmpty) RefillStep(refills),
    ];
  }

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
      for (var line = 0; line < _lineCount; line++)
        [
          for (var k = 0; k < _lineLength; k++)
            if (board.isPlayable(_lineCell(line, k))) _lineCell(line, k),
        ],
    ].where((cells) => cells.length >= 3).toList()
      ..shuffle(rng);
    final n = min(_ingredientTotal, _maxActiveIngredients);
    for (final cells in columns.take(n)) {
      board[cells[rng.nextInt((cells.length + 1) ~/ 2)]] = _makeIngredient();
    }
    if (MoveFinder.findMove(board) == null) BoardFactory.shuffle(board, rng);
  }

  /// Every bomb loses a turn; those at zero explode (the piece is lost and
  /// so is the level).
  List<BoardStep> _tickBombs() {
    final ticks = <int, int>{};
    final blown = <Pos>[];
    for (final p in board.positions) {
      final piece = board[p];
      if (piece == null || piece.timer == 0) continue;
      ticks[piece.id] = --piece.timer;
      if (piece.timer == 0) blown.add(p);
    }
    if (ticks.isEmpty) return const [];
    final exploded = [
      for (final p in blown) ClearedPiece(board[p]!.id, p),
    ];
    for (final p in blown) {
      board[p] = null;
    }
    if (blown.isNotEmpty) _bombed = true;
    return [
      BombStep(ticks, exploded),
      if (blown.isNotEmpty) ..._gravityAndRefill(),
      if (blown.isNotEmpty) ..._cascade(MatchFinder.find(board), startAt: 1),
    ];
  }

  /// Fire jumps from a burning piece to one neighbour. Called on turns where
  /// no burning piece was cleared.
  List<BoardStep> _spreadFire() {
    final pool = <Pos>{};
    for (final p in board.positions) {
      if (!(board[p]?.burning ?? false)) continue;
      for (final d in const [Pos(0, 1), Pos(0, -1), Pos(1, 0), Pos(-1, 0)]) {
        final q = p + d;
        final piece = board[q];
        if (piece != null &&
            !piece.burning &&
            !piece.frozen &&
            !piece.ingredient) {
          pool.add(q);
        }
      }
    }
    if (pool.isEmpty) return const [];
    final cells = pool.toList();
    final at = cells[rng.nextInt(cells.length)];
    board[at]!.burning = true;
    return [IgniteStep(at, board[at]!.id)];
  }

  /// Every cat that was not startled this turn steps onto a neighbouring
  /// piece and eats it (no score, no goal progress).
  List<BoardStep> _prowlCats() {
    final steps = <BoardStep>[];
    final wanted = {
      for (final g in goals)
        if (g.goal.type == GoalType.collect && !g.done) g.goal.piece,
    };
    for (final cat in List.of(_cats)) {
      if (_scared.contains(cat.id)) continue;
      final options = [
        for (final d in const [Pos(0, 1), Pos(0, -1), Pos(1, 0), Pos(-1, 0)])
          if (board[cat.pos + d] case final piece?
              when !piece.isSpecial &&
                  !piece.frozen &&
                  !piece.ingredient &&
                  !board.isLocked(cat.pos + d))
            cat.pos + d,
      ];
      if (options.isEmpty) continue;
      // Cats go for the fish the customer ordered.
      final fancy = [
        for (final p in options)
          if (wanted.contains(board[p]!.kind)) p,
      ];
      final pool = fancy.isNotEmpty && rng.nextDouble() < 0.7 ? fancy : options;
      final to = pool[rng.nextInt(pool.length)];
      final eaten = board[to]!;
      steps.add(CatMoveStep(cat.id, cat.pos, to));
      cat.pos = to;
      board[to] = null;
      steps
        ..add(ClearStep([ClearedPiece(eaten.id, to)], const [], 0, 1))
        ..addAll(_gravityAndRefill())
        ..addAll(_cascade(MatchFinder.find(board), startAt: 1));
    }
    return steps;
  }

  /// A mat grows onto one open cell beside an existing mat, swallowing the
  /// piece there. Called on turns where no mat was destroyed.
  List<BoardStep> _spreadMats() {
    final pool = <Pos>{};
    for (var i = 0; i < _mats.length; i++) {
      if (!_mats[i]) continue;
      final m = Pos(i ~/ board.cols, i % board.cols);
      for (final d in const [Pos(0, 1), Pos(0, -1), Pos(1, 0), Pos(-1, 0)]) {
        final q = m + d;
        final piece = board[q];
        if (piece != null &&
            !piece.ingredient &&
            !piece.frozen &&
            !board.isLocked(q) &&
            !_cats.any((c) => c.pos == q)) {
          pool.add(q);
        }
      }
    }
    if (pool.isEmpty) return const [];
    final cells = pool.toList();
    final at = cells[rng.nextInt(cells.length)];
    final id = board[at]!.id;
    board[at] = null;
    board.closeCell(at);
    final i = at.row * board.cols + at.col;
    _bags[i] = 1;
    _mats[i] = true;
    return [
      MatSpreadStep(at, id),
      ..._gravityAndRefill(),
      ..._cascade(MatchFinder.find(board), startAt: 1),
    ];
  }

  Set<Pos> _row(int r) => {
        for (var c = 0; c < board.cols; c++)
          if (board.isPlayable(Pos(r, c))) Pos(r, c),
      };

  Set<Pos> _col(int c) => {
        for (var r = 0; r < board.rows; r++)
          if (board.isPlayable(Pos(r, c))) Pos(r, c),
      };

  Set<Pos> _square(Pos o, int radius) => {
        for (var dr = -radius; dr <= radius; dr++)
          for (var dc = -radius; dc <= radius; dc++)
            if (board.isPlayable(Pos(o.row + dr, o.col + dc)))
              Pos(o.row + dr, o.col + dc),
      };

  Set<Pos> _ofKind(PieceKind k) => {
        for (final p in board.positions)
          if (board[p]?.kind == k) p
      };

  /// Soy Fish prefers pieces a collect goal still needs.
  Pos? _fishTarget({required Set<Pos> avoid}) {
    final wanted = {
      for (final g in goals)
        if (g.goal.type == GoalType.collect && !g.done) g.goal.piece,
    };
    final candidates = [
      for (final p in board.positions)
        if (!avoid.contains(p) && board[p] != null && !board[p]!.ingredient) p,
    ];
    if (candidates.isEmpty) return null;
    final preferred =
        candidates.where((p) => wanted.contains(board[p]!.kind)).toList();
    final pool = preferred.isNotEmpty ? preferred : candidates;
    return pool[rng.nextInt(pool.length)];
  }
}
