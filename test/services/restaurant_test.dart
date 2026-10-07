import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/services/restaurant.dart';
import 'package:sushi_trio/services/store.dart';
import 'package:sushi_trio/services/wallet.dart';

import '../helpers/riverpod.dart';

void main() {
  final lantern = Restaurant.furniture[0];
  final stool = Restaurant.furniture[1];
  var now = DateTime(2026, 1, 1, 9);
  late ProviderContainer c;
  late RestaurantNotifier shop;
  RestaurantState state() => c.read(restaurantProvider);

  setUp(() {
    now = DateTime(2026, 1, 1, 9);
    c = testContainer(clock: () => now);
    shop = c.read(restaurantProvider.notifier);
  });

  test('stars keep the best result per level and add up', () {
    expect(shop.recordStars(1, 2), 2);
    expect(shop.recordStars(1, 1), 0);
    expect(shop.recordStars(1, 3), 1);
    shop.recordStars(2, 1);
    expect(state().earned, 4);
    expect(state().available, 4);
  });

  test('buying furniture needs stars and spends them', () {
    expect(shop.buyFurniture(lantern), isFalse);
    shop.recordStars(1, lantern.cost);
    expect(shop.buyFurniture(lantern), isTrue);
    expect(state().available, 0);
    expect(shop.buyFurniture(lantern), isFalse);
  });

  test('customers fill the till by the hour, up to a cap', () {
    shop.recordStars(1, 3);
    shop.buyFurniture(lantern);
    expect(shop.till(), 0);
    now = now.add(const Duration(hours: 2));
    expect(shop.till(), lantern.coinsPerHour * 2);
    now = now.add(const Duration(days: 3));
    expect(shop.till(), lantern.coinsPerHour * Restaurant.tillHours);
  });

  test('collecting moves the till into the wallet and empties it', () {
    shop.recordStars(1, 3);
    shop.buyFurniture(lantern);
    now = now.add(const Duration(hours: 1));
    final coins = c.read(walletProvider).coins;
    expect(shop.collect(), lantern.coinsPerHour);
    expect(c.read(walletProvider).coins, coins + lantern.coinsPerHour);
    expect(shop.till(), 0);
    expect(shop.collect(), 0);
  });

  test('buying more keeps what the till earned at the old rate', () {
    for (var i = 1; i <= 3; i++) {
      shop.recordStars(i, 3);
    }
    shop.buyFurniture(lantern);
    now = now.add(const Duration(hours: 1));
    shop.buyFurniture(stool);
    now = now.add(const Duration(hours: 1));
    expect(shop.till(),
        lantern.coinsPerHour + lantern.coinsPerHour + stool.coinsPerHour);
  });

  test('furniture, till and stars survive a restart; reset clears them', () {
    final store = MemoryStore();
    final first = testContainer(store: store, clock: () => now);
    first.read(restaurantProvider.notifier)
      ..recordStars(1, 3)
      ..buyFurniture(lantern);
    now = now.add(const Duration(hours: 1));

    final second = testContainer(store: store, clock: () => now);
    expect(second.read(restaurantProvider).isOwned(lantern), isTrue);
    expect(second.read(restaurantProvider).earned, 3);
    expect(
        second.read(restaurantProvider.notifier).till(), lantern.coinsPerHour);

    second.read(restaurantProvider.notifier).reset();
    expect(second.read(restaurantProvider).earned, 0);
    expect(second.read(restaurantProvider).isOwned(lantern), isFalse);
    expect(testContainer(store: store).read(restaurantProvider).earned, 0);
  });

  test('purchases from the old per-region restaurants are refunded', () {
    final store = MemoryStore()
      ..put('stars_1', 3)
      ..put('restaurant_owned', ['shop:osaka', 'decor:tsukiji:lantern']);
    final s = testContainer(store: store).read(restaurantProvider);
    expect(s.owned, isEmpty);
    expect(s.available, 3);
  });
}
