import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sushi_match/core/settings.dart';
import 'package:sushi_match/services/wallet.dart';
import 'package:sushi_match/ui/l10n.dart';

void main() {
  var now = DateTime(2026, 10, 6, 12);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 6, 12);
    Wallet.clock = () => now;
    await Wallet.load();
  });

  test('losing a life starts the 30 minute regeneration clock', () {
    Wallet.loseLife();
    expect(Wallet.lives.value, 4);
    expect(Wallet.nextLifeIn, const Duration(minutes: 30));

    now = now.add(const Duration(minutes: 31));
    Wallet.tick();
    expect(Wallet.lives.value, 5);
    expect(Wallet.nextLifeIn, isNull);
  });

  test('lives never drop below zero or regenerate past the cap', () {
    for (var i = 0; i < 9; i++) {
      Wallet.loseLife();
    }
    expect(Wallet.lives.value, 0);
    now = now.add(const Duration(hours: 10));
    Wallet.tick();
    expect(Wallet.lives.value, Wallet.maxLives);
  });

  test('refill costs coins and fails when broke', () {
    Wallet.loseLife();
    expect(Wallet.refillLifeWithCoins(), isTrue);
    expect(Wallet.lives.value, 5);
    expect(Wallet.coins.value, Wallet.startingCoins - Wallet.lifeRefillCost);
    Wallet.loseLife();
    Wallet.coins.value = 0;
    expect(Wallet.refillLifeWithCoins(), isFalse);
  });

  test('boosters use stock first, then coins', () {
    Wallet.stock.value = {Booster.shuffle: 1};
    expect(Wallet.consume(Booster.shuffle), isTrue);
    expect(Wallet.coins.value, Wallet.startingCoins);
    expect(Wallet.consume(Booster.shuffle), isTrue);
    expect(Wallet.coins.value,
        Wallet.startingCoins - Wallet.cost[Booster.shuffle]!);
    Wallet.coins.value = 0;
    expect(Wallet.consume(Booster.shuffle), isFalse);
  });

  test('shop: single price, bundle discount, and stock goes up', () {
    expect(Wallet.price(Booster.chopsticks, 1), 15);
    expect(Wallet.price(Booster.chopsticks, 3), 36); // 45 less 20%
    expect(Wallet.buy(Booster.chopsticks, 3), isTrue);
    expect(Wallet.count(Booster.chopsticks), 3);
    expect(Wallet.coins.value, Wallet.startingCoins - 36);
  });

  test('shop: buying fails without enough coins and changes nothing', () {
    Wallet.coins.value = 10;
    expect(Wallet.buy(Booster.extraMoves, 1), isFalse);
    expect(Wallet.count(Booster.extraMoves), 0);
    expect(Wallet.coins.value, 10);
  });

  test('every string exists in both languages', () {
    const keys = [
      'pickPlate',
      'win',
      'lose',
      'chopsticks',
      'extraMoves',
      'shop',
      'owned',
      'bought',
      'bundleSave',
      'descShuffle',
      'livesFull',
    ];
    for (final lang in L10n.languages.keys) {
      Settings.language.value = lang;
      for (final k in keys) {
        expect(L10n.t(k), isNot(k), reason: '$lang/$k');
      }
    }
    Settings.language.value = 'en';
    expect(L10n.t('clearFirst', {'n': 3}), 'Clear level 3 first');
  });
}
