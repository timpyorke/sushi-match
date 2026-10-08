import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/services/restaurant.dart';
import 'package:sushi_trio/ui/map/japan_map.dart';

void main() {
  final layout = MapLayout(Restaurant.shops, Restaurant.totalLevels);

  test('map rows are rectangular and use only legend characters', () {
    expect(layout.grid.length, layout.rows);
    for (final row in layout.grid) {
      expect(row.length, kMapCols);
      for (final ch in row.split('')) {
        expect(kMapLegend.containsKey(ch), isTrue, reason: 'unknown "$ch"');
      }
    }
  });

  test('every level sits on land, climbing the map in level order', () {
    final total = Restaurant.totalLevels;
    expect(layout.nodes.length, total);
    for (var i = 0; i < total; i++) {
      final p = layout.nodes[i];
      expect(layout.tileAt(p.dx.floor(), p.dy.floor()), isNot(MapTile.sea),
          reason: 'level ${i + 1} is in the sea');
      if (i > 0) {
        expect(layout.nodeDist[i], greaterThan(layout.nodeDist[i - 1]));
      }
    }
    // Tokyo (level 1) is below the last restaurant.
    expect(layout.nodes.first.dy, greaterThan(layout.nodes.last.dy));
  });

  test('the route between levels stays on land', () {
    final end = layout.nodeDist.last;
    for (var d = 0.0; d <= end; d += 0.25) {
      final p = layout.pointAt(d);
      expect(layout.tileAt(p.dx.floor(), p.dy.floor()), isNot(MapTile.sea),
          reason: 'route in the sea at $p');
    }
  });

  test('level plates in a restaurant never crowd each other', () {
    for (final shop in layout.shops) {
      final ns = [
        for (var n = shop.firstLevel; n <= shop.lastLevel; n++)
          layout.nodes[n - 1],
      ];
      for (var i = 0; i < ns.length; i++) {
        for (var j = i + 1; j < ns.length; j++) {
          expect((ns[i] - ns[j]).distance, greaterThan(1.1),
              reason: '${shop.id}: levels ${shop.firstLevel + i} and '
                  '${shop.firstLevel + j}');
        }
      }
    }
  });

  test('neighbouring restaurants have different map shapes', () {
    for (var s = 1; s < layout.shops.length; s++) {
      expect(
          (layout.shapeOf(s), layout.mirrored(s)) ==
              (layout.shapeOf(s - 1), layout.mirrored(s - 1)),
          isFalse);
    }
  });

  test('each restaurant shows every decoration once, on land, off the route',
      () {
    for (var s = 0; s < layout.shops.length; s++) {
      final kinds = <String>[];
      for (var r = layout.bandTop(s); r < layout.bandTop(s) + kBandRows; r++) {
        for (var c = 0; c < kMapCols; c++) {
          final k = layout.sceneryAt(c, r);
          if (k == null) continue;
          kinds.add(k);
          expect(layout.tileAt(c, r), isNot(MapTile.sea));
          for (final (_, p) in layout.routeStones) {
            expect(p.dx.floor() == c && p.dy.floor() == r, isFalse,
                reason: '$k on the route at ($c, $r)');
          }
        }
      }
      expect(kinds, unorderedEquals(MapLayout.sceneryKinds),
          reason: layout.shops[s].id);
    }
  });
}
