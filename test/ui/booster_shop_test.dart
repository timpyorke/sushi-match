import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_match/services/store.dart';
import 'package:sushi_match/services/wallet.dart';
import 'package:sushi_match/ui/shop_screen.dart';

import '../helpers/riverpod.dart';

void main() {
  sheetTests();

  testWidgets('lists every booster and buying one adds it to the stock',
      (tester) async {
    // Cards are tall; make room so the lazy list builds every one.
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = testContainer();
    await tester
        .pumpWidget(scope(c, const MaterialApp(home: BoosterShopScreen())));
    expect(find.text('Chopsticks'), findsOneWidget);
    expect(find.text('Free swap'), findsOneWidget);
    expect(find.text('Shuffle'), findsOneWidget);
    expect(find.text('+5 moves'), findsOneWidget);

    // ×1 buttons come first in each card; Chopsticks is the second card.
    await tester.tap(find.text('×1  ').at(1));
    await tester.pump();
    final wallet = c.read(walletProvider);
    expect(wallet.count(Booster.chopsticks), 1);
    expect(
        wallet.coins, Wallet.startingCoins - Wallet.cost[Booster.chopsticks]!);
    expect(find.text('Purchased!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('too few coins shows a message and buys nothing', (tester) async {
    final c = testContainer(store: MemoryStore({'coins': 0}));
    await tester
        .pumpWidget(scope(c, const MaterialApp(home: BoosterShopScreen())));
    await tester.tap(find.text('×1  ').first);
    await tester.pump();
    expect(find.text('Not enough coins'), findsOneWidget);
    expect(c.read(walletProvider).count(Booster.extraMoves), 0);
  });
}

void sheetTests() {
  testWidgets('the in-level sheet buys boosters too', (tester) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = testContainer();
    await tester.pumpWidget(scope(
        c,
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
                onPressed: () => showBoosterShopSheet(context),
                child: const Text('open')),
          ),
        )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Shuffle'), findsOneWidget);

    await tester.tap(find.text('×1  ').at(3)); // Shuffle, the 4th card
    await tester.pump();
    expect(c.read(walletProvider).count(Booster.shuffle), 1);
    expect(tester.takeException(), isNull);
  });
}
