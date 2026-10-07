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
/// decoration the template's `m`/`f`/`c` characters become there.
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

/// One band of the map (top to bottom), one per restaurant. Row 2 is where the
/// band's last level sits and row 10 its first; rows 0-1 are left free for the
/// name banner. Any number of levels (up to ~20) is spread along the band's
/// path, so a restaurant of 10 or 15 levels needs no map change; more bands
/// are stacked above, so the map grows with `Restaurant.shops`.
const _bandTemplate = [
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
];

/// Path of the levels through one band, in tile coordinates (tile centres),
/// running from the bottom of the band to the top.
const _bandPath = [
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
];

/// Where everything sits on the tile grid. The first restaurant is the
/// bottom band, so the player climbs the map from Tokyo up to Hokkaido.
class MapLayout {
  MapLayout(this.shops, this.levelCount) {
    final bands = shops.length;
    rows = bands * kBandRows;

    grid = [
      for (var b = 0; b < bands; b++)
        ..._bandRows(regionOf(shops[bands - 1 - b].id),
            mirrored: (bands - 1 - b).isOdd),
    ];

    final pts = <Offset>[];
    for (var s = 0; s < bands; s++) {
      final dy = bandTop(s) * 1.0;
      for (final p in _bandPath) {
        // Odd bands run the other way round, so the route snakes up the map.
        pts.add(Offset(s.isOdd ? kMapCols - p.dx : p.dx, p.dy + dy));
      }
    }
    path = pts;
    _cum = [0];
    for (var i = 1; i < pts.length; i++) {
      _cum.add(_cum.last + (pts[i] - pts[i - 1]).distance);
    }

    final nodeList = <Offset>[];
    final distList = <double>[];
    for (var s = 0; s < bands; s++) {
      final start = _cum[s * _bandPath.length];
      final end = _cum[(s + 1) * _bandPath.length - 1];
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

  /// First row of the band belonging to shop index [s].
  int bandTop(int s) => (shops.length - 1 - s) * kBandRows;

  /// Shop index owning map row [row].
  int shopOfRow(int row) => shops.length - 1 - row ~/ kBandRows;

  MapTile tileAt(int col, int row) => kMapLegend[grid[row][col]]!;

  Iterable<String> _bandRows(MapRegion r, {required bool mirrored}) =>
      _bandTemplate.map((row) {
        final out = StringBuffer();
        for (final ch in (mirrored ? row.split('').reversed : row.split(''))) {
          out.write(r.deco[ch] ?? ch);
        }
        return out.toString();
      });

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
