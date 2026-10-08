part of 'game_engine.dart';

/// Clearing cells: chained specials, scoring, and what a clear does to the
/// obstacles in and beside the cleared cells.
extension _Clear on GameEngine {
  /// Clears [seed], chain-activating any specials hit along the way, and
  /// lets the clear hit the obstacles in and beside the cleared cells.
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
    // Iced pieces hit by a blast or touched by a clear lose one layer.
    final cracked = <Pos>{};
    final cleared = _chainSpecials(seed, consumed, cracked, steps);
    for (final q in cleared.expand((p) => p.neighbours)) {
      if (board[q]?.frozen ?? false) cracked.add(q);
    }
    final bagsHit = {
      for (final q in cleared.expand((p) => p.neighbours))
        if (bagAt(q) > 0) q,
    };
    final startled = _startleCats(cleared);

    final opened = <PieceKind>{};
    final removed = _removePieces(cleared, opened);
    final created = _spawnSpecials(spawns);
    final gained =
        _credit ? removed.length * GameEngine._pointsPerPiece * cascade : 0;
    score += gained;
    steps.add(ClearStep(removed, created, gained, cascade));

    final noriLeft = <Pos, int>{};
    for (final p in cleared) {
      final i = _idx(p);
      if (_nori[i] > 0) noriLeft[p] = --_nori[i];
    }
    if (noriLeft.isNotEmpty) steps.add(NoriStep(noriLeft));
    if (startled.isNotEmpty) steps.add(CatHitStep(startled));
    steps.addAll(_openLocks(opened));
    if (bagsHit.isNotEmpty) steps.add(_hitBags(bagsHit));
    if (cracked.isNotEmpty) {
      steps.add(IceStep([
        for (final p in cracked) IceHit(board[p]!.id, p, --board[p]!.ice),
      ]));
    }
    return steps;
  }

  /// The cells [seed] clears once every special it hits has fired (adding a
  /// [SpecialActivateStep] to [steps] for each). Frozen pieces in the way go
  /// to [cracked] instead.
  Set<Pos> _chainSpecials(Set<Pos> seed, Set<Pos> consumed, Set<Pos> cracked,
      List<BoardStep> steps) {
    final cleared = <Pos>{};
    final activated = <Pos>{...consumed};
    final queue = Queue<Pos>();

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
    return cleared;
  }

  /// Cats on or beside a cleared cell lose a life and skip their next prowl;
  /// those out of lives leave the board.
  List<CatHit> _startleCats(Set<Pos> cleared) {
    final startled = <CatHit>[];
    for (final cat in _cats) {
      final near =
          cleared.contains(cat.pos) || cat.pos.neighbours.any(cleared.contains);
      if (!near) continue;
      cat.hp--;
      _scared.add(cat.id);
      startled.add(CatHit(cat.id, cat.pos, cat.hp));
    }
    _cats.removeWhere((c) => c.hp <= 0);
    return startled;
  }

  /// Takes the [cleared] pieces off the board, counting them toward collect
  /// goals; kinds that open a key lock go to [opened].
  List<ClearedPiece> _removePieces(Set<Pos> cleared, Set<PieceKind> opened) {
    final removed = <ClearedPiece>[];
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
    return removed;
  }

  /// Puts the special each match group earned on its spawn cell.
  List<SpawnedPiece> _spawnSpecials(List<MatchGroup> spawns) {
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
    return created;
  }

  /// Matching a lock's colour opens every lock of that colour for good.
  List<BoardStep> _openLocks(Set<PieceKind> opened) => [
        for (final kind in opened)
          if (_unlocked.add(kind)) _unlock(kind),
      ];

  UnlockStep _unlock(PieceKind kind) {
    final cells = [
      for (final e in _lockKinds.entries)
        if (e.value == kind) e.key,
    ];
    board.lockedCells.removeAll(cells);
    return UnlockStep(cells, kind);
  }

  /// Each bag or mat in [cells] loses a layer; at zero its cell opens.
  BagStep _hitBags(Set<Pos> cells) {
    final hits = <BagHit>[];
    for (final q in cells) {
      final i = _idx(q);
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
    return BagStep(hits);
  }
}
