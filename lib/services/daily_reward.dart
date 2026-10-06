import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'store.dart';
import 'wallet.dart';

class DailyPrize {
  const DailyPrize(this.coins, [this.booster, this.qty = 0]);
  final int coins;
  final Booster? booster;
  final int qty;
}

/// The 7-day prize table. Day 7 is the biggest.
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
}

/// A 7-day login cycle: one prize a day. Missing a day restarts the cycle at
/// day 1. Dates are local calendar days, so there is no timer and nothing
/// runs in the background.
@immutable
class DailyState {
  const DailyState({this.day = -1, this.last});

  /// Index (0-6) of the prize last claimed; -1 before the first claim.
  final int day;
  final DateTime? last;

  static DateTime _midnight(DateTime t) => DateTime(t.year, t.month, t.day);

  bool canClaim(DateTime now) {
    final l = last;
    return l == null || _midnight(now).isAfter(l);
  }

  /// Index (0-6) of the prize that the next claim pays.
  int nextDay(DateTime now) {
    final l = last;
    if (l == null || day < 0) return 0;
    // Whole calendar days; rounding keeps it DST-safe.
    final gap = (_midnight(now).difference(l).inHours / 24).round();
    return gap == 1 ? (day + 1) % DailyReward.prizes.length : 0;
  }
}

class DailyNotifier extends Notifier<DailyState> {
  static const _lastKey = 'daily_last';
  static const _dayKey = 'daily_day';

  DateTime _now() => ref.read(clockProvider)();

  @override
  DailyState build() {
    final s = ref.read(storeProvider);
    final last = s.get<String>(_lastKey);
    return DailyState(
        day: s.get<int>(_dayKey) ?? -1,
        last: last == null ? null : DateTime.tryParse(last));
  }

  bool get canClaim => state.canClaim(_now());

  int get nextDay => state.nextDay(_now());

  /// Pays today's prize and returns it, or null if already claimed today.
  /// [doubled] doubles the coins (for a future rewarded ad).
  DailyPrize? claim({bool doubled = false}) {
    if (!canClaim) return null;
    final day = nextDay;
    final prize = DailyReward.prizes[day];
    final wallet = ref.read(walletProvider.notifier);
    wallet.earn(prize.coins * (doubled ? 2 : 1));
    if (prize.booster != null) wallet.grant(prize.booster!, prize.qty);
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    state = DailyState(day: day, last: today);
    final s = ref.read(storeProvider);
    s.put(_dayKey, day);
    s.put(_lastKey, today.toIso8601String());
    return prize;
  }

  void reset() {
    final s = ref.read(storeProvider);
    s.remove(_dayKey);
    s.remove(_lastKey);
    state = const DailyState();
  }
}

final dailyProvider =
    NotifierProvider<DailyNotifier, DailyState>(DailyNotifier.new);
