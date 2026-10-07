import 'dart:io';

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
    final n = Customer.roster.length;
    expect(Customer.forLevel(n + 1).nameKey, Customer.forLevel(1).nameKey);
  });

  test('every customer sprite has its frames bundled', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final c in Customer.roster.where((c) => c.sprite != null)) {
      expect(pubspec, contains('assets/sprites/customers/${c.sprite}/'));
      for (final anim in CustomerAnim.values) {
        for (var i = 0; i < Customer.frameCount; i++) {
          expect(File(c.frame(anim, i)).existsSync(), isTrue,
              reason: c.frame(anim, i));
        }
      }
    }
  });

  String shownFrame(WidgetTester tester) =>
      ((tester.widget<Image>(find.byType(Image)).image) as AssetImage)
          .assetName;

  testWidgets('sprite plays the intro, then loops the animation',
      (tester) async {
    const granny = Customer('👵', 'cust0', sprite: '00-granny-sakura');
    await tester.pumpWidget(const MaterialApp(
        home: CustomerSprite(
            customer: granny, intro: CustomerAnim.talk, introLoops: 1)));
    expect(shownFrame(tester), granny.frame(CustomerAnim.talk, 0));
    await tester.pump(const Duration(milliseconds: 520)); // 6 fps → frame 3
    expect(shownFrame(tester), granny.frame(CustomerAnim.talk, 3));
    // The intro ends at 667 ms, then idle runs at its slower 4 fps.
    await tester.pump(const Duration(milliseconds: 340)); // 860 ms
    expect(shownFrame(tester), granny.frame(CustomerAnim.idle, 0));
    await tester.pump(const Duration(milliseconds: 200)); // 1060 ms
    expect(shownFrame(tester), granny.frame(CustomerAnim.idle, 1));
  });

  testWidgets('customers without art show their emoji', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: CustomerSprite(customer: Customer('🐱', 'cust3'))));
    expect(find.text('🐱'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
