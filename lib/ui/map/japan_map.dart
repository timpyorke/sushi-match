import 'dart:ui';

import '../../services/restaurant.dart';

/// Kinds of tile the map can show. Add a tile by adding a value here, a
/// character to [kMapLegend] and a case in `TileMapPainter`.
enum MapTile { sea, land, mountain, forest, city }

/// Characters used in the map rows.
const kMapLegend = {
  '.': MapTile.sea,
  'L': MapTile.land,
  'm': MapTile.mountain,
  'f': MapTile.forest,
  'c': MapTile.city,
};

const kMapCols = 8;

/// Rows each restaurant's band takes on the map.
const kBandRows = 12;

/// Look of one restaurant's band: header colours, land colour, and which
/// decoration a band shape's `m`/`f`/`c` characters become there.
class MapRegion {
  const MapRegion(
      {required this.kanji,
      required this.top,
      required this.bottom,
      required this.land,
      this.deco = const {}});
  final String kanji;
  final Color top, bottom, land;
  final Map<String, String> deco;
}

const kMapRegions = {
  'tsukiji': MapRegion(
      kanji: '東京',
      top: Color(0xFF4FA3D1),
      bottom: Color(0xFF2B6E99),
      land: Color(0xFFA8C97F),
      deco: {'m': 'c', 'f': 'c'}),
  'osaka': MapRegion(
      kanji: '大阪',
      top: Color(0xFFF08A3C),
      bottom: Color(0xFFC25A16),
      land: Color(0xFFE6C47A),
      deco: {'m': 'c'}),
  'kyoto': MapRegion(
      kanji: '京都',
      top: Color(0xFFE56B8F),
      bottom: Color(0xFFB03A60),
      land: Color(0xFFB5D18A),
      deco: {'c': 'f'}),
  'hokkaido': MapRegion(
      kanji: '北海道',
      top: Color(0xFF6FC3C9),
      bottom: Color(0xFF3A8A98),
      land: Color(0xFFE8F2F4),
      deco: {'c': 'm', 'f': 'm'}),
  'fukuoka': MapRegion(
      kanji: '福岡',
      top: Color(0xFF5B5FC7),
      bottom: Color(0xFF353A8C),
      land: Color(0xFFC9B27E),
      deco: {'m': 'c', 'f': 'c', 'c': 'c'}),
  'okinawa': MapRegion(
      kanji: '沖縄',
      top: Color(0xFF2EC4B6),
      bottom: Color(0xFF138A8A),
      land: Color(0xFFF0DFAE),
      deco: {'m': 'f', 'c': 'f'}),
  'omakase': MapRegion(
      kanji: '極',
      top: Color(0xFFD4A537),
      bottom: Color(0xFF9A6A12),
      land: Color(0xFFD9C08A),
      deco: {'m': 'c', 'f': 'c'}),
  'nagoya': MapRegion(
      kanji: '名古屋',
      top: Color(0xFFE0A030),
      bottom: Color(0xFFA86E10),
      land: Color(0xFFD8CF8E),
      deco: {'m': 'c'}),
  'hiroshima': MapRegion(
      kanji: '広島',
      top: Color(0xFF3F8FB5),
      bottom: Color(0xFF235E7F),
      land: Color(0xFFB9D49A),
      deco: {'c': 'f'}),
  'kanazawa': MapRegion(
      kanji: '金沢',
      top: Color(0xFFC9A227),
      bottom: Color(0xFF8C6D0F),
      land: Color(0xFFCFE0B0),
      deco: {'m': 'f'}),
  'sendai': MapRegion(
      kanji: '仙台',
      top: Color(0xFF7A4FA8),
      bottom: Color(0xFF4E2D75),
      land: Color(0xFFC4D3A6),
      deco: {'c': 'f', 'f': 'm'}),
  'kobe': MapRegion(
      kanji: '神戸',
      top: Color(0xFF2F6DB5),
      bottom: Color(0xFF1B467F),
      land: Color(0xFFD6CDA8),
      deco: {'m': 'c', 'f': 'c'}),
  'nara': MapRegion(
      kanji: '奈良',
      top: Color(0xFF6FA84F),
      bottom: Color(0xFF437A2C),
      land: Color(0xFFA9CF86),
      deco: {'c': 'f', 'm': 'f'}),
  'ginza': MapRegion(
      kanji: '銀座',
      top: Color(0xFFB0B7C3),
      bottom: Color(0xFF6E7685),
      land: Color(0xFFD8D2C4),
      deco: {'m': 'c', 'f': 'c'}),
};

/// Fallback for a restaurant added without a region entry yet, so a missing
/// entry never crashes the map (a test still insists every shop has one).
const kDefaultRegion = MapRegion(
    kanji: '寿司',
    top: Color(0xFF8E8E9A),
    bottom: Color(0xFF5E5E6B),
    land: Color(0xFFBFD3A0));

MapRegion regionOf(String shopId) => kMapRegions[shopId] ?? kDefaultRegion;

/// The shape of one band of the map: its rows (top to bottom) and the path
/// of its levels in tile coordinates (tile centres), from the bottom of the
/// band to the top.
///
/// Every shape keeps the same joints so any two bands fit together: rows 0
/// and 11 are a neck of land in columns 2-5, rows 0-1 stay free for the name
/// banner, and the path starts at (3.5, 10.5) and ends at (3.5, 2.5). Any
/// number of levels (up to ~20) is spread along the path, so a restaurant of
/// 10 or 15 levels needs no map change.
class BandShape {
  const BandShape(this.rows, this.path);
  final List<String> rows;
  final List<Offset> path;
}

const kBandShapes = [
  // Zigzag across the island, with tabs of land on both sides.
  BandShape([
    '..LLLL..',
    '.LmLLfL.',
    '.LLLLLL.',
    'LLcLLmLL',
    '.LLLLLL.',
    '.LfLLfL.',
    '.LLLLLL.',
    'LLLmLcLL',
    '.LLLLLL.',
    '.LLfLLL.',
    '.LLLLLL.',
    '..LLLL..',
  ], [
    Offset(3.5, 10.5),
    Offset(6.5, 10.5),
    Offset(6.5, 8.5),
    Offset(1.5, 8.5),
    Offset(1.5, 6.5),
    Offset(6.5, 6.5),
    Offset(6.5, 4.5),
    Offset(1.5, 4.5),
    Offset(1.5, 2.5),
    Offset(3.5, 2.5),
  ]),
  // Spiral in round a lagoon, then out the far side.
  BandShape([
    '..LLLL..',
    '.LLLLLL.',
    'LLLLLLL.',
    '.LLLLLLL',
    '.LLLLLLL',
    '.LLLLLL.',
    'LLLL..LL',
    '.LLL..LL',
    '.LLL..L.',
    '.LLLLLL.',
    '.LLLLLLL',
    '..LLLL..',
  ], [
    Offset(3.5, 10.5),
    Offset(6.5, 10.5),
    Offset(6.5, 4.5),
    Offset(3.5, 4.5),
    Offset(3.5, 8.5),
    Offset(1.5, 8.5),
    Offset(1.5, 2.5),
    Offset(3.5, 2.5),
  ]),
  // Three long crossings with bays biting in from the sides.
  BandShape([
    '..LLLL..',
    '.LLLLLL.',
    '..LLLLLL',
    '..LLLLL.',
    '.LLLLLL.',
    'LLLLLLLL',
    '.LLLLLL.',
    '.LLLLLLL',
    'LLLLLLLL',
    '..LLLLL.',
    '..LLLLLL',
    '..LLLL..',
  ], [
    Offset(3.5, 10.5),
    Offset(6.5, 10.5),
    Offset(6.5, 8.0),
    Offset(1.5, 8.0),
    Offset(1.5, 5.5),
    Offset(6.5, 5.5),
    Offset(6.5, 2.5),
    Offset(3.5, 2.5),
  ]),
  // Slanting climb up a ragged coast, with short steps at the turns.
  BandShape([
    '..LLLL..',
    '.LLLLLL.',
    '..LLLLLL',
    '.LLLLLLL',
    'LLLLLLL.',
    '.LLLLLL.',
    'LLLLLL..',
    '.LLLLLLL',
    '..LLLLLL',
    '.LLLLLLL',
    'LLLLLLL.',
    '..LLLL..',
  ], [
    Offset(3.5, 10.5),
    Offset(6.5, 9.5),
    Offset(6.5, 8.0),
    Offset(1.5, 6.5),
    Offset(1.5, 5.0),
    Offset(6.5, 3.5),
    Offset(6.5, 2.5),
    Offset(3.5, 2.5),
  ]),
];

/// Where everything sits on the tile grid. The first restaurant is the
/// bottom band, so the player climbs the map from Tokyo up to Hokkaido.
class MapLayout {
  MapLayout(this.shops, this.levelCount) {
    final bands = shops.length;
    rows = bands * kBandRows;

    grid = [
      for (var b = bands - 1; b >= 0; b--)
        ..._bandRows(regionOf(shops[b].id), shapeOf(b), mirrored: mirrored(b)),
    ];

    final pts = <Offset>[];
    // Index in [path] where each band's own points start.
    final firstPoint = <int>[];
    for (var s = 0; s < bands; s++) {
      final dy = bandTop(s) * 1.0;
      firstPoint.add(pts.length);
      for (final p in shapeOf(s).path) {
        pts.add(Offset(mirrored(s) ? kMapCols - p.dx : p.dx, p.dy + dy));
      }
    }
    firstPoint.add(pts.length);
    path = pts;
    _cum = [0];
    for (var i = 1; i < pts.length; i++) {
      _cum.add(_cum.last + (pts[i] - pts[i - 1]).distance);
    }

    final nodeList = <Offset>[];
    final distList = <double>[];
    for (var s = 0; s < bands; s++) {
      final start = _cum[firstPoint[s]];
      final end = _cum[firstPoint[s + 1] - 1];
      final count = shops[s].lastLevel - shops[s].firstLevel + 1;
      for (var j = 0; j < count; j++) {
        final d = count == 1 ? start : start + (end - start) * j / (count - 1);
        distList.add(d);
        nodeList.add(pointAt(d));
      }
    }
    nodes = nodeList.take(levelCount).toList();
    nodeDist = distList.take(levelCount).toList();
  }

  final List<ShopDef> shops;
  final int levelCount;
  late final int rows;

  /// Map rows, top to bottom, one character per tile.
  late final List<String> grid;

  /// Waypoints of the whole route, starting at the first level.
  late final List<Offset> path;

  /// Centre of each level (index `level - 1`), in tile coordinates.
  late final List<Offset> nodes;

  /// Distance along [path] of each level.
  late final List<double> nodeDist;
  late final List<double> _cum;

  /// Whether level [n] is the last of its restaurant (the boss level).
  bool isShopEnd(int n) => shops.any((s) => s.lastLevel == n);

  /// First row of the band belonging to shop index [s].
  int bandTop(int s) => (shops.length - 1 - s) * kBandRows;

  /// Shop index owning map row [row].
  int shopOfRow(int row) => shops.length - 1 - row ~/ kBandRows;

  MapTile tileAt(int col, int row) => kMapLegend[grid[row][col]]!;

  /// Shape of shop index [s]'s band. Shapes take turns, and each is
  /// mirrored one time round and not the next, so neighbouring restaurants
  /// never look alike and the same look only comes back after
  /// 2 x [kBandShapes] bands.
  BandShape shapeOf(int s) => kBandShapes[s % kBandShapes.length];

  /// Whether shop index [s]'s band is drawn mirrored left to right.
  bool mirrored(int s) => s.isOdd != (s ~/ kBandShapes.length).isOdd;

  Iterable<String> _bandRows(MapRegion r, BandShape shape,
          {required bool mirrored}) =>
      shape.rows.map((row) {
        final out = StringBuffer();
        for (final ch in (mirrored ? row.split('').reversed : row.split(''))) {
          out.write(r.deco[ch] ?? ch);
        }
        return out.toString();
      });

  /// Stepping stones along the route (distance, point), in tile units. Built
  /// once: [pointAt] is a linear scan, too slow to call per stone per frame.
  late final List<(double, Offset)> routeStones = [
    if (nodeDist.isNotEmpty)
      for (var d = 0.0; d <= nodeDist.last; d += 0.4) (d, pointAt(d)),
  ];

  /// The decorations every region has a sprite for.
  static const sceneryKinds = [
    'landmark',
    'special',
    'mountain',
    'forest',
    'city'
  ];

  /// The decorations on the map: each restaurant shows each of
  /// [sceneryKinds] once.
  late final List<Scenery> scenery = _placeScenery();

  /// Size of a decoration on the map, in tiles. The largest at which every
  /// restaurant still fits all of [sceneryKinds] (see the map test).
  static const sceneryScale = 1.1;

  /// Whether a decoration centred on [at] stays on land, below the
  /// restaurant's name banner (rows 0-1 of band [s]) and clear of the
  /// stepping stones and of the level plates with their stars below. (The
  /// current level's marker floats above everything, so it may overlap.)
  bool _sceneryFits(Offset at, int s) {
    final box =
        Rect.fromCenter(center: at, width: sceneryScale, height: sceneryScale);
    final top = bandTop(s);
    if (box.top < top + 2 || box.bottom > top + kBandRows) return false;
    // The sprite's corners are transparent: it may hang over the coast a
    // little, but its body has to be on land.
    final body = box.deflate(sceneryScale * 0.2);
    for (final p in [
      body.topLeft,
      body.topRight,
      body.bottomLeft,
      body.bottomRight,
      at,
    ]) {
      final c = p.dx.floor(), r = p.dy.floor();
      if (c < 0 || c >= kMapCols || tileAt(c, r) == MapTile.sea) return false;
    }
    // The sprite fills about the middle 80% of its box.
    final art = box.deflate(sceneryScale * 0.1);
    final stones = art.inflate(0.3);
    for (final (_, p) in routeStones) {
      if (stones.contains(p)) return false;
    }
    for (final n in nodes) {
      if (Rect.fromLTRB(n.dx - 0.55, n.dy - 0.6, n.dx + 0.55, n.dy + 0.95)
          .overlaps(art)) {
        return false;
      }
    }
    return true;
  }

  /// Picks free spots on a half-tile grid in each band, never touching each
  /// other, the shape's scenery tiles first, and gives each a different
  /// decoration: the one the shape asks for when still unused, else the
  /// next unused kind.
  List<Scenery> _placeScenery() {
    const byChar = {'m': 'mountain', 'f': 'forest', 'c': 'city'};
    String? asked(Offset at) => byChar[grid[at.dy.floor()][at.dx.floor()]];
    final out = <Scenery>[];
    for (var s = 0; s < shops.length; s++) {
      final top = bandTop(s);
      final spots = <Offset>[
        for (var y = top + 2.5; y <= top + kBandRows - 0.5; y += 0.5)
          for (var x = 0.5; x <= kMapCols - 0.5; x += 0.5)
            if (_sceneryFits(Offset(x, y), s)) Offset(x, y),
      ];
      int rank(Offset p) {
        final x = (p.dx * 2).round(), y = (p.dy * 2).round();
        final onTile = (p.dx % 1 == 0.5 && p.dy % 1 == 0.5) ? 0 : 1;
        final shaped = asked(p) != null && onTile == 0 ? 0 : 1;
        return (shaped << 22) + ((x * 73856093) ^ (y * 19349663)) % 1000003;
      }

      spots.sort((p, q) => rank(p).compareTo(rank(q)));
      final picked = <Offset>[];
      for (final p in spots) {
        if (picked.length == sceneryKinds.length) break;
        if (picked.any((q) =>
            (q.dx - p.dx).abs() < sceneryScale + 0.2 &&
            (q.dy - p.dy).abs() < sceneryScale + 0.2)) {
          continue;
        }
        picked.add(p);
      }
      final unused = [...sceneryKinds];
      final kinds = <Offset, String>{};
      for (final p in picked) {
        final wanted = asked(p);
        if (wanted != null && unused.remove(wanted)) kinds[p] = wanted;
      }
      for (final p in picked) {
        kinds[p] ??= unused.removeAt(0);
      }
      kinds.forEach((p, kind) => out.add(Scenery(p, kind, s)));
    }
    return out;
  }

  Offset pointAt(double d) {
    for (var i = 1; i < path.length; i++) {
      if (d <= _cum[i] || i == path.length - 1) {
        final seg = _cum[i] - _cum[i - 1];
        final t = seg == 0 ? 0.0 : ((d - _cum[i - 1]) / seg).clamp(0.0, 1.0);
        return Offset.lerp(path[i - 1], path[i], t)!;
      }
    }
    return path.first;
  }

  /// The route from the first level up to distance [d].
  List<Offset> pathUpTo(double d) {
    final out = <Offset>[path.first];
    for (var i = 1; i < path.length; i++) {
      if (_cum[i] <= d) {
        out.add(path[i]);
      } else {
        out.add(pointAt(d));
        break;
      }
    }
    return out;
  }
}

/// One decoration on the map: what it is, where its centre sits (in tiles)
/// and which restaurant's art it uses.
class Scenery {
  const Scenery(this.at, this.kind, this.shop);
  final Offset at;
  final String kind;

  /// Shop index of the band it stands in.
  final int shop;
}
