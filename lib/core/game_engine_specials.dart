part of 'game_engine.dart';

/// Where specials hit, alone and in combos.
extension _Specials on GameEngine {
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
    final wanted = _wantedKinds;
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
