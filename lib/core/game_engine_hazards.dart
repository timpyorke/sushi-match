part of 'game_engine.dart';

/// What the board does by itself at the end of a turn: cats prowl, fire
/// and mats spread, bombs tick.
extension _Hazards on GameEngine {
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
      if (blown.isNotEmpty) ..._settleAndCascade(startAt: 1),
    ];
  }

  /// Fire jumps from a burning piece to one neighbour, unless a burning
  /// piece was cleared this turn.
  List<BoardStep> _spreadFire() {
    if (_fireOut) return const [];
    final pool = <Pos>{};
    for (final p in board.positions) {
      if (!(board[p]?.burning ?? false)) continue;
      for (final q in p.neighbours) {
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
    final wanted = _wantedKinds;
    for (final cat in List.of(_cats)) {
      if (_scared.contains(cat.id)) continue;
      final options = [
        for (final q in cat.pos.neighbours)
          if (board[q] case final piece?
              when !piece.isSpecial &&
                  !piece.frozen &&
                  !piece.ingredient &&
                  !board.isLocked(q))
            q,
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
        ..addAll(_settleAndCascade(startAt: 1));
    }
    return steps;
  }

  /// A mat grows onto one open cell beside an existing mat, swallowing the
  /// piece there, unless a mat was destroyed this turn.
  List<BoardStep> _spreadMats() {
    if (_matBroken) return const [];
    final pool = <Pos>{};
    for (var i = 0; i < _mats.length; i++) {
      if (!_mats[i]) continue;
      for (final q in _posOf(i).neighbours) {
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
    final i = _idx(at);
    _bags[i] = 1;
    _mats[i] = true;
    return [
      MatSpreadStep(at, id),
      ..._settleAndCascade(startAt: 1),
    ];
  }
}
