import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/ui/splash_screen.dart';

import '../helpers/riverpod.dart';

Widget _app(VoidCallback onDone) => MaterialApp(
    home: SplashScreen(
        onDone: onDone, duration: const Duration(milliseconds: 500)));

void main() {
  testWidgets('calls onDone once after the duration', (tester) async {
    testContainer();
    var n = 0;
    await tester.pumpWidget(_app(() => n++));
    expect(find.text('Sushi Trio'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 200));
    expect(n, 0);
    await tester.pump(const Duration(milliseconds: 400));
    expect(n, 1);
  });

  testWidgets('tap skips and onDone fires only once', (tester) async {
    testContainer();
    var n = 0;
    await tester.pumpWidget(_app(() => n++));
    await tester.tap(find.byType(SplashScreen));
    expect(n, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(n, 1);
  });

  testWidgets('no overflow on a narrow screen', (tester) async {
    testContainer();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(() {}));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  });
}
