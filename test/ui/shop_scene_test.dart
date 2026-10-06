import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sushi_match/services/restaurant.dart';
import 'package:sushi_match/services/wallet.dart';
import 'package:sushi_match/ui/restaurant_screen.dart';

void main() {
  testWidgets('tapping an empty spot buys it and the decoration appears',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Wallet.load();
    await Restaurant.load();
    await Restaurant.recordStars(1, 3);
    await tester.pumpWidget(const MaterialApp(home: RestaurantScreen()));

    // Price tags show; the real decoration is scaled to zero.
    expect(find.text('3'), findsOneWidget);
    expect(Restaurant.decorOwned(Restaurant.shops[0], Restaurant.shops[0].decor[0]),
        isFalse);

    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();

    expect(Restaurant.decorOwned(Restaurant.shops[0], Restaurant.shops[0].decor[0]),
        isTrue);
    expect(Restaurant.available, 0);
    expect(tester.takeException(), isNull);
  });
}
