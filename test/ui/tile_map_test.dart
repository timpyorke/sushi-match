import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/services/restaurant.dart';
import 'package:sushi_trio/ui/map/japan_map.dart';

void main() {
  final layout = MapLayout(Restaurant.shops, 60);

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
    expect(layout.nodes.length, 60);
    for (var i = 0; i < 60; i++) {
      final p = layout.nodes[i];
      expect(layout.tileAt(p.dx.floor(), p.dy.floor()), isNot(MapTile.sea),
          reason: 'level ${i + 1} is in the sea');
      if (i > 0) {
        expect(layout.nodeDist[i], greaterThan(layout.nodeDist[i - 1]));
      }
    }
    // Tokyo (level 1) is below Hokkaido (level 60).
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
}
