import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/core/game_engine.dart';
import 'package:sushi_trio/core/level.dart';
import 'package:sushi_trio/ui/customer_order.dart';
import 'package:sushi_trio/ui/level_intro.dart';

void main() {
  final level = LevelConfig.fromJson({
    'id': 1,
    'board': {'cols': 7, 'rows': 7},
    'pieces': ['salmon', 'maguro', 'tamago'],
    'moves': 20,
    'goals': [
      {'type': 'collect', 'piece': 'salmon', 'count': 20},
    ],
    'seed': 1,
  });
  final goals = [GoalProgress(level.goals.first, 0)];

  Future<List<bool>> pumpIntro(WidgetTester tester) async {
    final done = <bool>[];
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Stack(children: [
        Align(
            alignment: Alignment.topCenter,
            child: OrderBubble(key: key, level: level, goals: goals)),
        Positioned.fill(
          child: LevelIntro(
              level: level,
              goals: goals,
              target: key,
              onDone: () => done.add(true)),
        ),
      ]),
    ));
    await tester.pump(); // measure the target
    return done;
  }

  /// Steps frame by frame, as a real screen would, plus a little slack.
  Future<void> pumpFor(WidgetTester tester, Duration d) async {
    const frame = Duration(milliseconds: 16);
    for (var t = Duration.zero; t < d + frame * 6; t += frame) {
      await tester.pump(frame);
    }
  }

  Text spoken(WidgetTester tester) => tester.widget<Text>(find
      .descendant(of: find.byType(LevelIntro), matching: find.byType(Text))
      .at(1));

  testWidgets('types the order, then lands on the bubble', (tester) async {
    final done = await pumpIntro(tester);
    await tester.pump(LevelIntro.pop + LevelIntro.perChar * 5);
    final early = spoken(tester).textSpan!.toPlainText();
    expect(early, orderText(level.goals)); // laid out in full…
    expect(
        ((spoken(tester).textSpan! as TextSpan).children!.first as TextSpan)
            .text,
        hasLength(lessThan(10))); // …but only a few characters shown
    expect(done, isEmpty);

    await pumpFor(tester, LevelIntro.length(level));
    expect(done, [true]);
  });

  testWidgets('a tap skips to the flight', (tester) async {
    final done = await pumpIntro(tester);
    await tester.pump(LevelIntro.pop);
    await tester.tapAt(const Offset(10, 500));
    await pumpFor(tester, LevelIntro.fly);
    expect(done, [true]);
  });
}
