import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/services/restaurant.dart';
import 'package:sushi_trio/services/store.dart';
import 'package:sushi_trio/services/wallet.dart';

import '../helpers/riverpod.dart';

void main() {
  final tsukiji = Restaurant.shops[0];
  final osaka = Restaurant.shops[1];
  late ProviderContainer c;
  late RestaurantNotifier shops;
  RestaurantState state() => c.read(restaurantProvider);

  setUp(() {
    c = testContainer();
    shops = c.read(restaurantProvider.notifier);
  });

  test('stars keep the best result per level and add up', () {
    expect(shops.recordStars(1, 2), 2);
    expect(shops.recordStars(1, 1), 0);
    expect(shops.recordStars(1, 3), 1);
    shops.recordStars(2, 1);
    expect(state().earned, 4);
    expect(state().available, 4);
  });

  test('buying needs stars and spends them', () {
    expect(shops.buyDecor(tsukiji, tsukiji.decor[0]), isFalse);
    shops.recordStars(1, 3);
    expect(shops.buyDecor(tsukiji, tsukiji.decor[0]), isTrue);
    expect(state().available, 0);
    expect(shops.buyDecor(tsukiji, tsukiji.decor[0]), isFalse);
  });

  test('second restaurant gates its levels until bought', () {
    expect(state().maxPlayableLevel, 15);
    expect(shops.buyShop(osaka), isFalse);
    for (var i = 1; i <= 8; i++) {
      shops.recordStars(i, 3);
    }
    expect(shops.buyShop(osaka), isTrue);
    expect(state().maxPlayableLevel, 30);
    expect(state().available, 0);
  });

  test('finishing a restaurant pays coins and a Chopsticks, once', () {
    for (var i = 1; i <= 6; i++) {
      shops.recordStars(i, 3);
    }
    final coins = c.read(walletProvider).coins;
    for (final d in tsukiji.decor) {
      expect(shops.buyDecor(tsukiji, d), isTrue);
    }
    expect(state().shopComplete(tsukiji), isTrue);
    final wallet = c.read(walletProvider);
    expect(wallet.coins, coins + Restaurant.completeCoins);
    expect(wallet.count(Booster.chopsticks), 1);
  });

  test('purchases and stars survive a restart; reset clears them', () {
    final store = MemoryStore();
    final first = testContainer(store: store);
    first.read(restaurantProvider.notifier)
      ..recordStars(1, 3)
      ..buyDecor(tsukiji, tsukiji.decor[0]);

    final second = testContainer(store: store);
    expect(
        second.read(restaurantProvider).decorOwned(tsukiji, tsukiji.decor[0]),
        isTrue);
    expect(second.read(restaurantProvider).earned, 3);

    second.read(restaurantProvider.notifier).reset();
    expect(second.read(restaurantProvider).earned, 0);
    expect(
        second.read(restaurantProvider).decorOwned(tsukiji, tsukiji.decor[0]),
        isFalse);
    expect(testContainer(store: store).read(restaurantProvider).earned, 0);
  });
}
