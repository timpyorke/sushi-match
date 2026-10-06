import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_match/game/sushi_game.dart';
import 'package:sushi_match/services/store.dart';
import 'package:sushi_match/services/wallet.dart';

import '../core/helpers.dart';
import '../helpers/riverpod.dart';

void main() {
  test('a starter booster is spent when the level starts', () {
    final c = testContainer(store: MemoryStore({'booster_starterKnife': 1}));
    SushiGame(
        level: testLevel(),
        wallet: c.read(walletProvider.notifier),
        starters: const [Booster.starterKnife]);
    final wallet = c.read(walletProvider);
    expect(wallet.count(Booster.starterKnife), 0);
    expect(wallet.coins, Wallet.startingCoins);
  });

  test('an unowned starter is ignored, never bought with coins', () {
    final c = testContainer();
    SushiGame(
        level: testLevel(),
        wallet: c.read(walletProvider.notifier),
        starters: const [Booster.starterWasabi]);
    expect(c.read(walletProvider).coins, Wallet.startingCoins);
  });
}
