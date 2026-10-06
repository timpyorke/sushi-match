import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/services/restaurant.dart';
import 'package:sushi_trio/ui/restaurant_screen.dart';

import '../helpers/riverpod.dart';

void main() {
  testWidgets('tapping an empty spot buys it and the decoration appears',
      (tester) async {
    final c = testContainer();
    c.read(restaurantProvider.notifier).recordStars(1, 3);
    final shop = Restaurant.shops[0];
    bool owned() => c.read(restaurantProvider).decorOwned(shop, shop.decor[0]);
    await tester
        .pumpWidget(scope(c, const MaterialApp(home: RestaurantScreen())));

    // Price tags show; the real decoration is scaled to zero.
    expect(find.text('3'), findsOneWidget);
    expect(owned(), isFalse);

    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();

    expect(owned(), isTrue);
    expect(c.read(restaurantProvider).available, 0);
    expect(tester.takeException(), isNull);
  });
}
