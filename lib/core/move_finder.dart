import 'board.dart';
import 'pos.dart';

abstract final class MoveFinder {
  static const _dirs = [Pos(0, 1), Pos(1, 0)];

  /// First valid move in row-major order, or null (→ shuffle).
  static (Pos, Pos)? findMove(Board b) {
    for (final m in _iterate(b)) {
      return m;
    }
    return null;
  }

  static List<(Pos, Pos)> allMoves(Board b) => _iterate(b).toList();

  static Iterable<(Pos, Pos)> _iterate(Board b) sync* {
    for (final p in b.positions) {
      for (final d in _dirs) {
        final q = p + d;
        if (!b.isPlayable(q) || b.isLocked(p) || b.isLocked(q)) continue;
        final pa = b[p], pb = b[q];
        if (pa == null || pb == null || pa.frozen || pb.frozen) continue;
        if (pa.isOmakase || pb.isOmakase || (pa.isSpecial && pb.isSpecial)) {
          yield (p, q);
          continue;
        }
        b.swap(p, q);
        final ok = hasMatchAt(b, p) || hasMatchAt(b, q);
        b.swap(p, q);
        if (ok) yield (p, q);
      }
    }
  }

  /// Cheap local check: does the piece at [p] belong to a 3-run or 2×2?
  static bool hasMatchAt(Board b, Pos p) {
    final k = b.matchKind(p);
    if (k == null) return false;
    bool same(int r, int c) => b.matchKind(Pos(r, c)) == k;

    var h = 1;
    for (var c = p.col - 1; same(p.row, c); c--) {
      h++;
    }
    for (var c = p.col + 1; same(p.row, c); c++) {
      h++;
    }
    if (h >= 3) return true;

    var v = 1;
    for (var r = p.row - 1; same(r, p.col); r--) {
      v++;
    }
    for (var r = p.row + 1; same(r, p.col); r++) {
      v++;
    }
    if (v >= 3) return true;

    for (final dr in const [-1, 0]) {
      for (final dc in const [-1, 0]) {
        final r = p.row + dr, c = p.col + dc;
        if (same(r, c) &&
            same(r, c + 1) &&
            same(r + 1, c) &&
            same(r + 1, c + 1)) {
          return true;
        }
      }
    }
    return false;
  }
}
