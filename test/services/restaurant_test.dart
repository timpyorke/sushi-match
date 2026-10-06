import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sushi_match/services/restaurant.dart';
import 'package:sushi_match/services/wallet.dart';

void main() {
  final tsukiji = Restaurant.shops[0];
  final osaka = Restaurant.shops[1];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Wallet.load();
    await Restaurant.load();
  });

  test('stars keep the best result per level and add up', () async {
    expect(await Restaurant.recordStars(1, 2), 2);
    expect(await Restaurant.recordStars(1, 1), 0);
    expect(await Restaurant.recordStars(1, 3), 1);
    await Restaurant.recordStars(2, 1);
    expect(Restaurant.earned, 4);
    expect(Restaurant.available, 4);
  });

  test('buying needs stars and spends them', () async {
    expect(await Restaurant.buyDecor(tsukiji, tsukiji.decor[0]), isFalse);
    await Restaurant.recordStars(1, 3);
    expect(await Restaurant.buyDecor(tsukiji, tsukiji.decor[0]), isTrue);
    expect(Restaurant.available, 0);
    expect(await Restaurant.buyDecor(tsukiji, tsukiji.decor[0]), isFalse);
  });

  test('second restaurant gates its levels until bought', () async {
    expect(Restaurant.maxPlayableLevel, 15);
    expect(await Restaurant.buyShop(osaka), isFalse);
    for (var i = 1; i <= 8; i++) {
      await Restaurant.recordStars(i, 3);
    }
    expect(await Restaurant.buyShop(osaka), isTrue);
    expect(Restaurant.maxPlayableLevel, 30);
    expect(Restaurant.available, 0);
  });

  test('finishing a restaurant pays coins and a Chopsticks, once', () async {
    for (var i = 1; i <= 6; i++) {
      await Restaurant.recordStars(i, 3);
    }
    final coins = Wallet.coins.value;
    for (final d in tsukiji.decor) {
      expect(await Restaurant.buyDecor(tsukiji, d), isTrue);
    }
    expect(Restaurant.shopComplete(tsukiji), isTrue);
    expect(Wallet.coins.value, coins + Restaurant.completeCoins);
    expect(Wallet.count(Booster.chopsticks), 1);
  });

  test('purchases and stars survive a reload; reset clears them', () async {
    await Restaurant.recordStars(1, 3);
    await Restaurant.buyDecor(tsukiji, tsukiji.decor[0]);
    await Restaurant.load();
    expect(Restaurant.decorOwned(tsukiji, tsukiji.decor[0]), isTrue);
    expect(Restaurant.earned, 3);
    await Restaurant.reset();
    expect(Restaurant.earned, 0);
    expect(Restaurant.decorOwned(tsukiji, tsukiji.decor[0]), isFalse);
  });
}
