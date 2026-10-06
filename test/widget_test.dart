import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/main.dart';
import 'package:sushi_trio/services/store.dart';
import 'package:sushi_trio/ui/ui_art.dart';

import 'helpers/riverpod.dart';

final _now = DateTime(2026, 1, 1, 12);

/// A store where today's daily reward is already claimed, so no dialog opens.
MemoryStore _store([Map<String, Object> extra = const {}]) => MemoryStore({
      'daily_last': DateTime(2026, 1, 1).toIso8601String(),
      'daily_day': 0,
      ...extra,
    });

Future<void> _pumpApp(WidgetTester tester, MemoryStore store) async {
  await tester.pumpWidget(
      scope(testContainer(store: store, clock: () => _now), const SushiTrioApp(showSplash: false)));
  await tester.pump();
}

Future<void> _openLevels(WidgetTester tester) async {
  await tester.tap(find.text('Levels'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  narrowTest();
  testWidgets('home offers Play for level 1 on a fresh install',
      (WidgetTester tester) async {
    await _pumpApp(tester, _store());

    expect(find.text('Sushi Trio'), findsWidgets);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);
  });

  testWidgets('home opens the daily reward when it is waiting',
      (WidgetTester tester) async {
    await tester.pumpWidget(scope(
        testContainer(store: MemoryStore(), clock: () => _now),
        const SushiTrioApp(showSplash: false)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Claim'), findsOneWidget);
    // The test font is wider than Mali, so the calendar may report overflow.
    tester.takeException();
  });

  testWidgets('only level 1 is open on a fresh install',
      (WidgetTester tester) async {
    await _pumpApp(tester, _store());
    await _openLevels(tester);

    expect(find.text('Pick a plate'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNWidgets(59));
  });

  testWidgets('clearing a level unlocks the next', (WidgetTester tester) async {
    await _pumpApp(
        tester,
        _store({
          'cleared_level': 3,
          'stars_1': 3,
          'stars_2': 1,
          'stars_3': 2
        }));

    // Play continues from the next level.
    expect(find.text('Level 4'), findsOneWidget);

    await _openLevels(tester);
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
    await _pumpApp(tester, _store());
    expect(tester.takeException(), isNull);
    await _openLevels(tester);
    expect(tester.takeException(), isNull);
  });
}
