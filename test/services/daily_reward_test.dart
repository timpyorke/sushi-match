import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sushi_match/services/daily_reward.dart';
import 'package:sushi_match/services/wallet.dart';

void main() {
  var now = DateTime(2026, 10, 6, 9);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 6, 9);
    Wallet.clock = () => now;
    await Wallet.load();
    await DailyReward.load();
  });

  test('first claim pays day 1 and only once a day', () async {
    expect(DailyReward.canClaim, isTrue);
    final p = await DailyReward.claim();
    expect(p!.coins, DailyReward.prizes[0].coins);
    expect(Wallet.coins.value, Wallet.startingCoins + p.coins);
    expect(DailyReward.canClaim, isFalse);
    expect(await DailyReward.claim(), isNull);

    now = DateTime(2026, 10, 6, 23, 59);
    expect(DailyReward.canClaim, isFalse);
  });

  test('consecutive days climb to day 7, then wrap to day 1', () async {
    for (var d = 0; d < 7; d++) {
      expect(DailyReward.nextDay, d);
      await DailyReward.claim();
      now = now.add(const Duration(days: 1));
    }
    expect(DailyReward.nextDay, 0);
    // Day 7 is the biggest prize.
    expect(DailyReward.prizes.last.coins,
        greaterThan(DailyReward.prizes.first.coins));
  });

  test('skipping a day restarts the cycle', () async {
    await DailyReward.claim();
    now = now.add(const Duration(days: 1));
    await DailyReward.claim();
    now = now.add(const Duration(days: 3));
    expect(DailyReward.canClaim, isTrue);
    expect(DailyReward.nextDay, 0);
  });

  test('booster prizes land in the stock and the claim survives a reload',
      () async {
    for (var d = 0; d < 3; d++) {
      await DailyReward.claim();
      now = now.add(const Duration(days: 1));
    }
    expect(Wallet.count(Booster.chopsticks), 1);
    await DailyReward.load();
    expect(DailyReward.nextDay, 3);
  });
}
