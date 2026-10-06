import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sushi_match/main.dart';
import 'package:sushi_match/ui/ui_art.dart';

void main() {
  narrowTest();
  testWidgets('only level 1 is open on a fresh install',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SushiMatchApp());
    await tester.pump();

    expect(find.text('Pick a plate'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNWidgets(49));
  });

  testWidgets('clearing a level unlocks the next', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'cleared_level': 3});
    await tester.pumpWidget(const SushiMatchApp());
    await tester.pump();

    expect(find.byIcon(Icons.lock), findsNWidgets(46));
    expect(find.byType(StarIcon), findsNWidgets(3));
  });
}

void narrowTest() {
  testWidgets('no overflow on a narrow phone', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SushiMatchApp());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
