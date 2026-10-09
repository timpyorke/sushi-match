import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/services/restaurant.dart';
import 'package:sushi_trio/ui/map/japan_map.dart';
import 'package:sushi_trio/ui/map/map_art.dart';
import 'package:sushi_trio/ui/map/tile_map_painter.dart';

void main() {
  testWidgets('all frame slices load and the map paints with the new cliffs',
      (tester) async {
    final art = (await tester.runAsync(MapArt.load))!;
    for (final kind in ['outer', 'inner']) {
      for (final part in [
        'top_left',
        'top',
        'top_right',
        'left',
        'right',
        'bottom_left',
        'bottom',
        'bottom_right',
      ]) {
        expect(art['cliff_${kind}_${part}_v2'], isNotNull,
            reason: 'Missing $kind $part cliff');
      }
    }
    final scroll = ScrollController();
    final layout = MapLayout(Restaurant.shops, Restaurant.totalLevels);
    await tester.pumpWidget(MaterialApp(
        home: CustomPaint(
      painter: TileMapPainter(
        layout: layout,
        tile: 40,
        reached: 0,
        scroll: scroll,
        art: art,
      ),
    )));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    scroll.dispose();
  });
}
