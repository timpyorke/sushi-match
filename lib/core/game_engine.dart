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
        movesLeft = level.moves {
    BoardFactory.fillInitial(board, level.pieces, rng, _makePiece);
  }

  GameEngine._fork(GameEngine o, int seed)
      : level = o.level,
        board = o.board.copy(),
        rng = Random(seed),
        _nori = List.of(o._nori),
        movesLeft = o.movesLeft,
        score = o.score,
        status = o.status,
        _nextId = o._nextId {
    _collected.addAll(o._collected);
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
  int _nextId = 0;

  /// Origins of Wasabi Bombs that still owe their second blast.
  final List<Pos> _aftershocks = [];
  final Map<PieceKind, int> _collected = {};

  List<GoalProgress> get goals => [
        for (final g in level.goals)
          GoalProgress(
            g,
            switch (g.type) {
              GoalType.collect => _collected[g.piece] ?? 0,
              GoalType.score => score,
              GoalType.clearNori => g.count - _nori.where((n) => n > 0).length,
            },
          ),
      ];

  int get stars => status != GameStatus.won
      ? 0
      : max(1, level.stars.where((s) => score >= s).length);

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

    final specialSwap =
        pa.isOmakase || pb.isOmakase || (pa.isSpecial && pb.isSpecial);
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
    if (status != GameStatus.playing || board[p] == null) return const [];
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
        board[b] == null) {
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
    if (spendMove && !goals.every((g) => g.done)) {
      shifted
        ..addAll(_runConveyors())
        ..addAll(_cascade(MatchFinder.find(board), startAt: 1));
    }
    if (spendMove) movesLeft--;
    final won = goals.every((g) => g.done);
    if (won) {
      status = GameStatus.won;
    } else if (movesLeft <= 0) {
      status = GameStatus.lost;
    }
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
        if (board[p] != null && !board[p]!.isSpecial) p,
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

    void mark(Pos p) {
      final piece = board[p];
      if (piece == null || !cleared.add(p)) return;
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

    final removed = <ClearedPiece>[];
    for (final p in cleared) {
      final piece = board[p]!;
      final k = piece.kind;
      if (k != null) _collected[k] = (_collected[k] ?? 0) + 1;
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

    final gained = removed.length * _pointsPerPiece * cascade;
    score += gained;
    steps.add(ClearStep(removed, created, gained, cascade));

    final noriLeft = <Pos, int>{};
    for (final p in cleared) {
      final i = p.row * board.cols + p.col;
      if (_nori[i] > 0) noriLeft[p] = --_nori[i];
    }
    if (noriLeft.isNotEmpty) steps.add(NoriStep(noriLeft));
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

  List<BoardStep> _gravityAndRefill() {
    final falls = <FallMove>[];
    final refills = <RefillPiece>[];
    for (var c = 0; c < board.cols; c++) {
      // Pieces fall straight down and skip over void cells.
      // TODO(rice-bag): diagonal slides once solid blockers exist.
      final cells = [
        for (var r = 0; r < board.rows; r++)
          if (board.isPlayable(Pos(r, c))) Pos(r, c),
      ];
      if (cells.isEmpty) continue;
      final stack = <(Pos, Piece)>[
        for (final p in cells)
          if (board[p] != null) (p, board[p]!),
      ];
      for (final p in cells) {
        board[p] = null;
      }
      var w = cells.length - 1;
      for (var i = stack.length - 1; i >= 0; i--, w--) {
        final (from, piece) = stack[i];
        final to = cells[w];
        board[to] = piece;
        if (from != to) falls.add(FallMove(piece.id, from, to));
      }
      final missing = w + 1;
      final top = cells.first.row;
      for (var i = 0; i < missing; i++) {
        final piece =
            _makePiece(level.pieces[rng.nextInt(level.pieces.length)]);
        board[cells[i]] = piece;
        refills.add(
            RefillPiece(PieceSnapshot.of(piece), cells[i], top - missing + i));
      }
    }
    return [
      if (falls.isNotEmpty) FallStep(falls),
      if (refills.isNotEmpty) RefillStep(refills),
    ];
  }

  // ------------------------------------------------------------- helpers --

  Piece _makePiece(PieceKind k) => Piece(id: _nextId++, kind: k);

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
        if (!avoid.contains(p) && board[p] != null) p,
    ];
    if (candidates.isEmpty) return null;
    final preferred =
        candidates.where((p) => wanted.contains(board[p]!.kind)).toList();
    final pool = preferred.isNotEmpty ? preferred : candidates;
    return pool[rng.nextInt(pool.length)];
  }
}
