import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_match/services/store.dart';
import 'package:sushi_match/services/wallet.dart';
import 'package:sushi_match/ui/l10n.dart';

import '../helpers/riverpod.dart';

void main() {
  var now = DateTime(2026, 10, 6, 12);
  late ProviderContainer c;
  late WalletNotifier wallet;
  WalletState state() => c.read(walletProvider);

  setUp(() {
    now = DateTime(2026, 10, 6, 12);
    c = testContainer(clock: () => now);
    wallet = c.read(walletProvider.notifier);
  });

  test('losing a life starts the 30 minute regeneration clock', () {
    wallet.loseLife();
    expect(state().lives, 4);
    expect(wallet.nextLifeIn, const Duration(minutes: 30));

    now = now.add(const Duration(minutes: 31));
    wallet.tick();
    expect(state().lives, 5);
    expect(wallet.nextLifeIn, isNull);
  });

  test('lives never drop below zero or regenerate past the cap', () {
    for (var i = 0; i < 9; i++) {
      wallet.loseLife();
    }
    expect(state().lives, 0);
    now = now.add(const Duration(hours: 10));
    wallet.tick();
    expect(state().lives, Wallet.maxLives);
  });

  test('refill costs coins and fails when broke', () {
    wallet.loseLife();
    expect(wallet.refillLifeWithCoins(), isTrue);
    expect(state().lives, 5);
    expect(state().coins, Wallet.startingCoins - Wallet.lifeRefillCost);
    wallet.loseLife();
    c.read(storeProvider).put('coins', 0);
    c.invalidate(walletProvider);
    wallet = c.read(walletProvider.notifier);
    expect(wallet.refillLifeWithCoins(), isFalse);
  });

  test('boosters use stock first, then coins', () {
    c.read(storeProvider).put('booster_shuffle', 1);
    c.invalidate(walletProvider);
    wallet = c.read(walletProvider.notifier);
    expect(wallet.consume(Booster.shuffle), isTrue);
    expect(state().coins, Wallet.startingCoins);
    expect(wallet.consume(Booster.shuffle), isTrue);
    expect(state().coins, Wallet.startingCoins - Wallet.cost[Booster.shuffle]!);
    c.read(storeProvider).put('coins', 0);
    c.invalidate(walletProvider);
    wallet = c.read(walletProvider.notifier);
    expect(wallet.consume(Booster.shuffle), isFalse);
  });

  test('shop: single price, bundle discount, and stock goes up', () {
    expect(Wallet.price(Booster.chopsticks, 1), 15);
    expect(Wallet.price(Booster.chopsticks, 3), 36); // 45 less 20%
    expect(wallet.buy(Booster.chopsticks, 3), isTrue);
    expect(state().count(Booster.chopsticks), 3);
    expect(state().coins, Wallet.startingCoins - 36);
  });

  test('shop: buying fails without enough coins and changes nothing', () {
    c.read(storeProvider).put('coins', 10);
    c.invalidate(walletProvider);
    wallet = c.read(walletProvider.notifier);
    expect(wallet.buy(Booster.extraMoves, 1), isFalse);
    expect(state().count(Booster.extraMoves), 0);
    expect(state().coins, 10);
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
      L10n.language = lang;
      for (final k in keys) {
        expect(L10n.t(k), isNot(k), reason: '$lang/$k');
      }
    }
    L10n.language = 'en';
    expect(L10n.t('clearFirst', {'n': 3}), 'Clear level 3 first');
  });
}
