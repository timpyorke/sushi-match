import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sushi_match/services/wallet.dart';
import 'package:sushi_match/ui/shop_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Wallet.load();
  });

  sheetTests();

  testWidgets('lists every booster and buying one adds it to the stock',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BoosterShopScreen()));
    expect(find.text('Chopsticks'), findsOneWidget);
    expect(find.text('Free swap'), findsOneWidget);
    expect(find.text('Shuffle'), findsOneWidget);
    expect(find.text('+5 moves'), findsOneWidget);

    // ×1 buttons come first in each card; Chopsticks is the second card.
    await tester.tap(find.text('×1  ').at(1));
    await tester.pump();
    expect(Wallet.count(Booster.chopsticks), 1);
    expect(Wallet.coins.value,
        Wallet.startingCoins - Wallet.cost[Booster.chopsticks]!);
    expect(find.text('Purchased!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('too few coins shows a message and buys nothing', (tester) async {
    Wallet.coins.value = 0;
    await tester.pumpWidget(const MaterialApp(home: BoosterShopScreen()));
    await tester.tap(find.text('×1  ').first);
    await tester.pump();
    expect(find.text('Not enough coins'), findsOneWidget);
    expect(Wallet.count(Booster.extraMoves), 0);
  });
}

void sheetTests() {
  testWidgets('the in-level sheet buys boosters too', (tester) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
            onPressed: () => showBoosterShopSheet(context),
            child: const Text('open')),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Shuffle'), findsOneWidget);

    await tester.tap(find.text('×1  ').at(3)); // Shuffle, the 4th card
    await tester.pump();
    expect(Wallet.count(Booster.shuffle), 1);
    expect(tester.takeException(), isNull);
  });
}
