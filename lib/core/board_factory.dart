import 'dart:math';

import 'board.dart';
import 'match_finder.dart';
import 'move_finder.dart';
import 'piece.dart';
import 'pos.dart';

abstract final class BoardFactory {
  /// Fills every playable cell so the board starts with no matches (no 3-runs,
  /// no 2×2) and at least one valid move.
  static void fillInitial(Board b, List<PieceKind> kinds, Random rng,
      Piece Function(PieceKind) make) {
    for (var attempt = 0; attempt < 100; attempt++) {
      for (final p in b.positions) {
        final banned = <PieceKind>{};
        final l1 = b[Pos(p.row, p.col - 1)]?.kind;
        final l2 = b[Pos(p.row, p.col - 2)]?.kind;
        final u1 = b[Pos(p.row - 1, p.col)]?.kind;
        final u2 = b[Pos(p.row - 2, p.col)]?.kind;
        final ul = b[Pos(p.row - 1, p.col - 1)]?.kind;
        if (l1 != null && l1 == l2) banned.add(l1);
        if (u1 != null && u1 == u2) banned.add(u1);
        if (l1 != null && l1 == u1 && l1 == ul) banned.add(l1);
        final allowed = [for (final k in kinds) if (!banned.contains(k)) k];
        final pool = allowed.isEmpty ? kinds : allowed;
        b[p] = make(pool[rng.nextInt(pool.length)]);
      }
      if (MatchFinder.find(b).isEmpty && MoveFinder.findMove(b) != null) {
        return;
      }
    }
    throw StateError('Could not generate a playable board');
  }

  /// Rearranges existing pieces until there are no matches and a move exists.
  /// Returns pieceId -> new position for the view.
  static Map<int, Pos> shuffle(Board b, Random rng) {
    final cells = [for (final p in b.positions) if (b[p] != null) p];
    final pieces = [for (final p in cells) b[p]!];
    for (var attempt = 0; attempt < 100; attempt++) {
      pieces.shuffle(rng);
      for (var i = 0; i < cells.length; i++) {
        b[cells[i]] = pieces[i];
      }
      if (MatchFinder.find(b).isEmpty && MoveFinder.findMove(b) != null) break;
    }
    return {for (var i = 0; i < cells.length; i++) pieces[i].id: cells[i]};
  }
}
