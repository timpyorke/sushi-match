import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/core/piece.dart';
import 'package:sushi_trio/services/restaurant.dart';
import 'package:sushi_trio/services/wallet.dart';
import 'package:sushi_trio/ui/restaurant_screen.dart';

import '../helpers/riverpod.dart';

void main() {
  testWidgets('tapping an empty spot buys furniture with stars',
      (tester) async {
    final c = testContainer();
    c.read(restaurantProvider.notifier).recordStars(1, 2);
    final lantern = Restaurant.furniture[0];
    bool owned() => c.read(restaurantProvider).isOwned(lantern);
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester
        .pumpWidget(scope(c, const MaterialApp(home: RestaurantScreen())));

    expect(owned(), isFalse);
    await tester.tap(find.text('${lantern.cost}').first);
    await tester.pump(const Duration(seconds: 1));

    expect(owned(), isTrue);
    expect(c.read(restaurantProvider).available, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sushi placed on the display case sells and the till pays out',
      (tester) async {
    var now = DateTime(2026, 1, 1, 9);
    final c = testContainer(clock: () => now);
    final shop = c.read(restaurantProvider.notifier)
      ..grantSushi([PieceKind.salmon]);
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester
        .pumpWidget(scope(c, const MaterialApp(home: RestaurantScreen())));

    // Open the first slot's picker and choose the salmon.
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salmon'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(c.read(restaurantProvider).slot(0), PieceKind.salmon);

    now = now.add(const Duration(minutes: 5));
    await tester.pump(const Duration(seconds: 1));
    final price = c.read(restaurantProvider).price(PieceKind.salmon);
    expect(c.read(restaurantProvider).banked, price);

    final coins = c.read(walletProvider).coins;
    await tester.tap(find.text('Collect'));
    await tester.pump(const Duration(seconds: 1));
    expect(c.read(walletProvider).coins, coins + price);
    expect(shop.till(), 0);
    expect(tester.takeException(), isNull);
  });
}
