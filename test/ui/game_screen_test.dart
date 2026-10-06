import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/main.dart';
import 'package:sushi_trio/ui/ui_art.dart';

import '../helpers/riverpod.dart';

void main() {
  testWidgets('a level has a shop button that fits a narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(scope(
        testContainer(), const MaterialApp(home: GameScreen(levelNumber: 1))));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ShopIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
