import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/services/daily_reward.dart';
import 'package:sushi_trio/services/store.dart';
import 'package:sushi_trio/services/wallet.dart';

import '../helpers/riverpod.dart';

void main() {
  var now = DateTime(2026, 10, 6, 9);
  late ProviderContainer c;
  late DailyNotifier daily;

  setUp(() {
    now = DateTime(2026, 10, 6, 9);
    c = testContainer(clock: () => now);
    daily = c.read(dailyProvider.notifier);
  });

  test('first claim pays day 1 and only once a day', () {
    expect(daily.canClaim, isTrue);
    final p = daily.claim();
    expect(p!.coins, DailyReward.prizes[0].coins);
    expect(c.read(walletProvider).coins, Wallet.startingCoins + p.coins);
    expect(daily.canClaim, isFalse);
    expect(daily.claim(), isNull);

    now = DateTime(2026, 10, 6, 23, 59);
    expect(daily.canClaim, isFalse);
  });

  test('consecutive days climb to day 7, then wrap to day 1', () {
    for (var d = 0; d < 7; d++) {
      expect(daily.nextDay, d);
      daily.claim();
      now = now.add(const Duration(days: 1));
    }
    expect(daily.nextDay, 0);
    // Day 7 is the biggest prize.
    expect(DailyReward.prizes.last.coins,
        greaterThan(DailyReward.prizes.first.coins));
  });

  test('skipping a day restarts the cycle', () {
    daily.claim();
    now = now.add(const Duration(days: 1));
    daily.claim();
    now = now.add(const Duration(days: 3));
    expect(daily.canClaim, isTrue);
    expect(daily.nextDay, 0);
  });

  test('booster prizes land in the stock and the claim survives a restart', () {
    final store = MemoryStore();
    c = testContainer(store: store, clock: () => now);
    daily = c.read(dailyProvider.notifier);
    for (var d = 0; d < 3; d++) {
      daily.claim();
      now = now.add(const Duration(days: 1));
    }
    expect(c.read(walletProvider).count(Booster.chopsticks), 1);

    final again = testContainer(store: store, clock: () => now);
    expect(again.read(dailyProvider.notifier).nextDay, 3);
  });
}
