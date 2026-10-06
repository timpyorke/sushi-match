import 'board.dart';
import 'piece.dart';
import 'pos.dart';

class MatchGroup {
  const MatchGroup(
      {required this.cells, required this.kind, this.spawn, this.spawnAt});

  final Set<Pos> cells;
  final PieceKind kind;
  final SpecialType? spawn;
  final Pos? spawnAt;
}

enum _Axis { h, v, square }

class _Unit {
  _Unit(this.cells, this.axis);
  final List<Pos> cells;
  final _Axis axis;
}

/// Finds every match on the board and decides which special each creates.
///
/// Priority (GDD): 5-line → Omakase, L/T → Wasabi, 4-line → Knife,
/// 2×2 → Soy Fish. Overlapping runs/squares merge into one group.
abstract final class MatchFinder {
  static List<MatchGroup> find(Board b, {Set<Pos> preferred = const {}}) {
    final units = <_Unit>[];

    for (var r = 0; r < b.rows; r++) {
      var c = 0;
      while (c < b.cols) {
        final k = b.matchKind(Pos(r, c));
        var end = c + 1;
        if (k != null) {
          while (end < b.cols && b.matchKind(Pos(r, end)) == k) {
            end++;
          }
          if (end - c >= 3) {
            units
                .add(_Unit([for (var i = c; i < end; i++) Pos(r, i)], _Axis.h));
          }
        }
        c = end;
      }
    }

    for (var c = 0; c < b.cols; c++) {
      var r = 0;
      while (r < b.rows) {
        final k = b.matchKind(Pos(r, c));
        var end = r + 1;
        if (k != null) {
          while (end < b.rows && b.matchKind(Pos(end, c)) == k) {
            end++;
          }
          if (end - r >= 3) {
            units
                .add(_Unit([for (var i = r; i < end; i++) Pos(i, c)], _Axis.v));
          }
        }
        r = end;
      }
    }

    for (var r = 0; r < b.rows - 1; r++) {
      for (var c = 0; c < b.cols - 1; c++) {
        final k = b.matchKind(Pos(r, c));
        if (k != null &&
            b.matchKind(Pos(r, c + 1)) == k &&
            b.matchKind(Pos(r + 1, c)) == k &&
            b.matchKind(Pos(r + 1, c + 1)) == k) {
          units.add(_Unit([
            Pos(r, c),
            Pos(r, c + 1),
            Pos(r + 1, c),
            Pos(r + 1, c + 1),
          ], _Axis.square));
        }
      }
    }

    if (units.isEmpty) return const [];

    // Union units that share a cell.
    final parent = List<int>.generate(units.length, (i) => i);
    int root(int i) {
      while (parent[i] != i) {
        parent[i] = parent[parent[i]];
        i = parent[i];
      }
      return i;
    }

    final owner = <Pos, int>{};
    for (var i = 0; i < units.length; i++) {
      for (final p in units[i].cells) {
        final o = owner[p];
        if (o == null) {
          owner[p] = i;
        } else {
          parent[root(i)] = root(o);
        }
      }
    }

    final byRoot = <int, List<_Unit>>{};
    for (var i = 0; i < units.length; i++) {
      byRoot.putIfAbsent(root(i), () => []).add(units[i]);
    }
    return [for (final us in byRoot.values) _toGroup(b, us, preferred)];
  }

  static MatchGroup _toGroup(Board b, List<_Unit> us, Set<Pos> preferred) {
    final cells = <Pos>{for (final u in us) ...u.cells};
    final kind = b[cells.first]!.kind!;
    final lines = us.where((u) => u.axis != _Axis.square).toList();
    final hs = lines.where((u) => u.axis == _Axis.h).toList();
    final vs = lines.where((u) => u.axis == _Axis.v).toList();
    final longest = lines.isEmpty
        ? null
        : lines.reduce((x, y) => x.cells.length >= y.cells.length ? x : y);
    final maxLen = longest?.cells.length ?? 0;

    SpecialType? spawn;
    Pos? anchor;
    if (maxLen >= 5) {
      spawn = SpecialType.omakase;
      anchor = _mid(longest!);
    } else if (hs.isNotEmpty && vs.isNotEmpty) {
      spawn = SpecialType.wasabi;
      anchor = _intersection(hs, vs) ?? _mid(longest!);
    } else if (maxLen == 4) {
      spawn = longest!.axis == _Axis.h
          ? SpecialType.knifeRow
          : SpecialType.knifeCol;
      anchor = _mid(longest);
    } else if (us.any((u) => u.axis == _Axis.square)) {
      spawn = SpecialType.soyFish;
      anchor = us.firstWhere((u) => u.axis == _Axis.square).cells.first;
    }

    if (spawn != null) {
      // The special appears where the player swapped, if that's in the group.
      final pref = preferred.where(cells.contains);
      if (pref.isNotEmpty) anchor = pref.first;
    }
    return MatchGroup(
        cells: cells,
        kind: kind,
        spawn: spawn,
        spawnAt: spawn == null ? null : anchor);
  }

  static Pos _mid(_Unit u) => u.cells[u.cells.length ~/ 2];

  static Pos? _intersection(List<_Unit> hs, List<_Unit> vs) {
    for (final h in hs) {
      for (final v in vs) {
        for (final p in h.cells) {
          if (v.cells.contains(p)) return p;
        }
      }
    }
    return null;
  }
}
