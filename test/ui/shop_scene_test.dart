import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/services/restaurant.dart';
import 'package:sushi_trio/services/wallet.dart';
import 'package:sushi_trio/ui/restaurant_screen.dart';

import '../helpers/riverpod.dart';

void main() {
  testWidgets('tapping an empty spot buys it and customers start paying',
      (tester) async {
    var now = DateTime(2026, 1, 1, 9);
    final c = testContainer(clock: () => now);
    c.read(restaurantProvider.notifier).recordStars(1, 2);
    final lantern = Restaurant.furniture[0];
    bool owned() => c.read(restaurantProvider).isOwned(lantern);
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester
        .pumpWidget(scope(c, const MaterialApp(home: RestaurantScreen())));

    // Price tags show; the real furniture is scaled to zero.
    expect(find.text('${lantern.cost}'), findsOneWidget);
    expect(owned(), isFalse);

    await tester.tap(find.text('${lantern.cost}'));
    // Customers walk in a loop, so the scene never settles.
    await tester.pump(const Duration(seconds: 1));

    expect(owned(), isTrue);
    expect(c.read(restaurantProvider).available, 0);

    now = now.add(const Duration(hours: 1));
    await tester.pump(const Duration(seconds: 1));
    final coins = c.read(walletProvider).coins;
    await tester.tap(find.text('Collect'));
    await tester.pump(const Duration(seconds: 1));
    expect(c.read(walletProvider).coins, coins + lantern.coinsPerHour);
    expect(tester.takeException(), isNull);
  });
}
