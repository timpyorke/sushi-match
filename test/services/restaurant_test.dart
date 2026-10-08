import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/core/piece.dart';
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

  test('winning a level pays sushi from its palette', () {
    final palette = [PieceKind.salmon, PieceKind.ebi, PieceKind.tamago];
    final won = Restaurant.rewardFor(4, 2, palette);
    expect(won.length, Restaurant.sushiReward(2));
    expect(won.every(palette.contains), isTrue);
    expect(Restaurant.rewardFor(1, 3, const []), isEmpty);
    shop.grantSushi(won);
    expect(state().stockTotal, won.length);
  });

  test('placing sushi moves it from the stock to a slot', () {
    expect(shop.place(PieceKind.salmon, 0), isFalse, reason: 'none in stock');
    shop.grantSushi([PieceKind.salmon, PieceKind.salmon]);
    expect(shop.place(PieceKind.salmon, 0), isTrue);
    expect(shop.place(PieceKind.salmon, 0), isFalse, reason: 'slot taken');
    expect(shop.place(PieceKind.salmon, state().slotCount), isFalse,
        reason: 'slot locked');
    expect(state().slot(0), PieceKind.salmon);
    expect(state().count(PieceKind.salmon), 1);
    expect(shop.take(0), isTrue);
    expect(state().count(PieceKind.salmon), 2);
    expect(state().since, isNull);
  });

  test('customers buy the sushi on display, one per visit', () {
    shop.grantSushi([PieceKind.salmon, PieceKind.maguro]);
    shop.place(PieceKind.salmon, 0);
    shop.place(PieceKind.maguro, 1);
    final every = state().visitEvery;
    final salmon = state().price(PieceKind.salmon);
    final maguro = state().price(PieceKind.maguro);
    expect(shop.till(), 0);

    now = now.add(Duration(seconds: every - 1));
    expect(shop.till(), 0);
    now = now.add(const Duration(seconds: 1));
    expect(shop.till(), salmon);

    now = now.add(Duration(seconds: every));
    shop.settle();
    expect(state().banked, salmon + maguro);
    expect(state().placed, 0);
    expect(state().since, isNull);

    // Time with an empty shelf earns nothing.
    now = now.add(const Duration(days: 3));
    shop.settle();
    expect(state().banked, salmon + maguro);
  });

  test('collecting moves the till into the wallet and empties it', () {
    shop.grantSushi([PieceKind.tamago]);
    shop.place(PieceKind.tamago, 0);
    now = now.add(const Duration(minutes: 5));
    final coins = c.read(walletProvider).coins;
    final price = state().price(PieceKind.tamago);
    expect(shop.collect(), price);
    expect(c.read(walletProvider).coins, coins + price);
    expect(shop.till(), 0);
    expect(shop.collect(), 0);
  });

  test('furniture raises prices and speeds customers up', () {
    for (var i = 1; i <= 3; i++) {
      shop.recordStars(i, 3);
    }
    final base = state().price(PieceKind.ikura);
    final slow = state().visitEvery;
    shop.buyFurniture(lantern);
    shop.buyFurniture(stool);
    expect(state().price(PieceKind.ikura), greaterThan(base));
    expect(state().visitEvery, lessThan(slow));
  });

  test('only dining furniture opens display slots', () {
    shop..recordStars(1, 3)..recordStars(2, 3);
    final slots = state().slotCount;
    shop.buyFurniture(lantern);
    expect(state().slotCount, slots);
    shop.buyFurniture(stool);
    expect(state().slotCount, slots + 1);
    expect(stool.category, FurnitureCategory.dining);
    expect(Restaurant.maxSlots, slots + 3);
  });

  test('every piece of furniture sits in a category', () {
    for (final cat in FurnitureCategory.values) {
      expect(Restaurant.inCategory(cat), isNotEmpty);
    }
    expect(FurnitureCategory.values.expand(Restaurant.inCategory).length,
        Restaurant.furniture.length);
  });

  test('sushi, shelf, till and stars survive a restart; reset clears them', () {
    final store = MemoryStore();
    final first = testContainer(store: store, clock: () => now);
    first.read(restaurantProvider.notifier)
      ..recordStars(1, 3)
      ..buyFurniture(lantern)
      ..grantSushi([PieceKind.ebi, PieceKind.ebi])
      ..place(PieceKind.ebi, 1);

    final second = testContainer(store: store, clock: () => now);
    final s = second.read(restaurantProvider);
    expect(s.isOwned(lantern), isTrue);
    expect(s.earned, 3);
    expect(s.slot(1), PieceKind.ebi);
    expect(s.count(PieceKind.ebi), 1);
    expect(s.since, isNotNull);

    now = now.add(const Duration(hours: 1));
    final third = testContainer(store: store, clock: () => now);
    expect(third.read(restaurantProvider).banked, greaterThan(0));
    expect(third.read(restaurantProvider).placed, 0);

    third.read(restaurantProvider.notifier).reset();
    expect(third.read(restaurantProvider).earned, 0);
    expect(third.read(restaurantProvider).stockTotal, 0);
    expect(third.read(restaurantProvider).isOwned(lantern), isFalse);
    final fresh = testContainer(store: store).read(restaurantProvider);
    expect(fresh.earned, 0);
    expect(fresh.stockTotal, 0);
    expect(fresh.placed, 0);
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
