import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'wallet.dart';

class DailyPrize {
  const DailyPrize(this.coins, [this.booster, this.qty = 0]);
  final int coins;
  final Booster? booster;
  final int qty;
}

/// A 7-day login cycle: one prize a day, day 7 the biggest. Missing a day
/// restarts the cycle at day 1. Dates are local calendar days, so there is
/// no timer and nothing runs in the background.
abstract final class DailyReward {
  static const prizes = [
    DailyPrize(20),
    DailyPrize(30),
    DailyPrize(30, Booster.chopsticks, 1),
    DailyPrize(40),
    DailyPrize(40, Booster.shuffle, 1),
    DailyPrize(50, Booster.starterKnife, 1),
    DailyPrize(150, Booster.extraMoves, 2),
  ];

  static const _lastKey = 'daily_last';
  static const _dayKey = 'daily_day';

  /// Index (0-6) of the prize last claimed; -1 before the first claim.
  static int _day = -1;
  static DateTime? _last;

  /// Bumped on every claim so listeners can refresh.
  static final revision = ValueNotifier<int>(0);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _day = prefs.getInt(_dayKey) ?? -1;
    final s = prefs.getString(_lastKey);
    _last = s == null ? null : DateTime.tryParse(s);
    revision.value++;
  }

  static DateTime _today() {
    final n = Wallet.clock();
    return DateTime(n.year, n.month, n.day);
  }

  static bool get canClaim {
    final last = _last;
    return last == null || _today().isAfter(last);
  }

  /// Index (0-6) of the prize that the next claim pays.
  static int get nextDay {
    final last = _last;
    if (last == null || _day < 0) return 0;
    // Calendar-day difference; DST-safe because both sides are midnights
    // rounded to whole days.
    final gap = (_today().difference(last).inHours / 24).round();
    return gap == 1 ? (_day + 1) % prizes.length : 0;
  }

  /// Pays today's prize and returns it, or null if already claimed today.
  /// [doubled] doubles the coins (for a future rewarded ad).
  static Future<DailyPrize?> claim({bool doubled = false}) async {
    if (!canClaim) return null;
    final day = nextDay;
    final prize = prizes[day];
    Wallet.earn(prize.coins * (doubled ? 2 : 1));
    if (prize.booster != null) Wallet.grant(prize.booster!, prize.qty);
    _day = day;
    _last = _today();
    revision.value++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dayKey, _day);
    await prefs.setString(_lastKey, _last!.toIso8601String());
    return prize;
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dayKey);
    await prefs.remove(_lastKey);
    _day = -1;
    _last = null;
    revision.value++;
  }
}
