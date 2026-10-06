import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/core/game_engine.dart';
import 'package:sushi_trio/core/level.dart';
import 'package:sushi_trio/core/piece.dart';
import 'package:sushi_trio/ui/l10n.dart';
import 'package:sushi_trio/ui/customer_order.dart';

void main() {
  final goals = [
    const LevelGoal.collect(PieceKind.salmon, 20),
    const LevelGoal.collect(PieceKind.tamago, 15),
    const LevelGoal.score(5000),
  ];

  test('order text lists every goal in English', () {
    L10n.language = 'en';
    expect(orderText(goals),
        "I'd like 20 Salmon, 15 Tamago and a 5000-point feast, please!");
    expect(orderText(goals.take(1).toList()), "I'd like 20 Salmon, please!");
  });

  test('order text is localised in Thai', () {
    L10n.language = 'th';
    addTearDown(() => L10n.language = 'en');
    expect(orderText(goals), contains('แซลมอน 20 ชิ้น'));
    expect(orderText(goals), contains('กับ'));
  });

  testWidgets('goal counts show progress and cap at the target',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Column(children: [
      GoalCount(progress: GoalProgress(goals[0], 7)),
      GoalCount(progress: GoalProgress(goals[1], 18)),
    ])));
    expect(find.text('7/20'), findsOneWidget);
    expect(find.text('15/15'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  test('every level gets a customer', () {
    expect(Customer.forLevel(1).emoji, isNotEmpty);
    expect(Customer.forLevel(7).nameKey, Customer.forLevel(1).nameKey);
  });
}
