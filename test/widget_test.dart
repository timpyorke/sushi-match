import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_match/main.dart';
import 'package:sushi_match/services/store.dart';
import 'package:sushi_match/ui/ui_art.dart';

import 'helpers/riverpod.dart';

void main() {
  narrowTest();
  testWidgets('only level 1 is open on a fresh install',
      (WidgetTester tester) async {
    await tester.pumpWidget(scope(testContainer(), const SushiMatchApp()));
    await tester.pump();

    expect(find.text('Pick a plate'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNWidgets(59));
  });

  testWidgets('clearing a level unlocks the next', (WidgetTester tester) async {
    await tester.pumpWidget(scope(
        testContainer(
            store: MemoryStore({
          'cleared_level': 3,
          'stars_1': 3,
          'stars_2': 1,
          'stars_3': 2
        })),
        const SushiMatchApp()));
    await tester.pump();

    expect(find.byIcon(Icons.lock), findsNWidgets(56));
    // Three stars under each cleared level, lit by the best result.
    expect(find.byType(StarIcon), findsNWidgets(9));
    expect(find.byWidgetPredicate((w) => w is StarIcon && w.lit),
        findsNWidgets(6));
  });
}

void narrowTest() {
  testWidgets('no overflow on a narrow phone', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(scope(testContainer(), const SushiMatchApp()));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
