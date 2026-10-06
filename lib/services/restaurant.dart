import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import 'store.dart';
import 'wallet.dart';

class DecorDef {
  const DecorDef(this.id, this.emoji, this.cost);
  final String id;
  final String emoji;
  final int cost;

  String get nameKey => 'decor_$id';
}

/// One restaurant: a block of levels, bought with stars, then decorated.
class ShopDef {
  const ShopDef(this.id, this.emoji, this.firstLevel, this.lastLevel,
      this.unlockCost, this.decor);
  final String id;
  final String emoji;
  final int firstLevel;
  final int lastLevel;
  final int unlockCost;
  final List<DecorDef> decor;

  String get nameKey => 'shop_$id';
}

/// Restaurant definitions and constants.
///
/// Pacing (a mid-skill bot averages ~2.2 stars a level): the first 15 levels
/// pay roughly 30 stars, so the second restaurant (24) plus the first one's
/// decoration (16) cannot both be afforded on the first pass. Replaying for
/// 3 stars closes the gap. Unlock costs after Hokkaido stay near 40 so that
/// buying every restaurant in turn (without decor) needs ~90% of the
/// stars available so far; decor is the optional star sink.
abstract final class Restaurant {
  static const shops = [
    ShopDef('tsukiji', '🐟', 1, 15, 0, [
      DecorDef('lantern', '🏮', 3),
      DecorDef('table', '🪑', 5),
      DecorDef('sign', '🪧', 8),
    ]),
    ShopDef('osaka', '🍢', 16, 30, 24, [
      DecorDef('lantern', '🏮', 5),
      DecorDef('table', '🪑', 8),
      DecorDef('sign', '🪧', 12),
    ]),
    ShopDef('kyoto', '⛩️', 31, 45, 40, [
      DecorDef('lantern', '🏮', 7),
      DecorDef('table', '🪑', 10),
      DecorDef('sign', '🪧', 14),
    ]),
    ShopDef('hokkaido', '🦀', 46, 60, 60, [
      DecorDef('lantern', '🏮', 8),
      DecorDef('table', '🪑', 12),
      DecorDef('sign', '🪧', 16),
    ]),
    ShopDef('fukuoka', '🍜', 61, 75, 38, [
      DecorDef('lantern', '🏮', 9),
      DecorDef('table', '🪑', 13),
      DecorDef('sign', '🪧', 18),
    ]),
    ShopDef('okinawa', '🌺', 76, 90, 40, [
      DecorDef('lantern', '🏮', 10),
      DecorDef('table', '🪑', 15),
      DecorDef('sign', '🪧', 20),
    ]),
    ShopDef('omakase', '👑', 91, 100, 42, [
      DecorDef('lantern', '🏮', 12),
      DecorDef('table', '🪑', 17),
      DecorDef('sign', '🪧', 24),
    ]),
  ];

  /// Number of levels in the game: the end of the last restaurant. To add
  /// levels, extend the last shop or append a new one (see
  /// docs/adding-levels.md).
  static int get totalLevels => shops.last.lastLevel;

  static const completeCoins = 100;

  static ShopDef? shopOfLevel(int level) {
    for (final s in shops) {
      if (level >= s.firstLevel && level <= s.lastLevel) return s;
    }
    return null;
  }
}

/// Stars earned from levels are spent on new restaurants and their
/// decorations. Spent stars are derived from what is owned, so there is no
/// counter to drift out of sync.
@immutable
class RestaurantState {
  const RestaurantState({this.best = const {}, this.owned = const {}});

  /// Best star count per level.
  final Map<int, int> best;

  /// 'shop:<id>' and 'decor:<shop>:<decor>' entries.
  final Set<String> owned;

  int get earned => best.values.fold(0, (a, b) => a + b);

  int get spent {
    var total = 0;
    for (final s in Restaurant.shops) {
      if (shopUnlocked(s)) total += s.unlockCost;
      for (final d in s.decor) {
        if (decorOwned(s, d)) total += d.cost;
      }
    }
    return total;
  }

  int get available => earned - spent;

  int bestStars(int level) => best[level] ?? 0;

  bool shopUnlocked(ShopDef s) =>
      s.unlockCost == 0 || owned.contains('shop:${s.id}');

  bool decorOwned(ShopDef s, DecorDef d) =>
      owned.contains('decor:${s.id}:${d.id}');

  bool shopComplete(ShopDef s) => s.decor.every((d) => decorOwned(s, d));

  /// Highest level the player may enter: the end of the last shop reached
  /// without skipping a locked one.
  int get maxPlayableLevel {
    var last = 0;
    for (final s in Restaurant.shops) {
      if (!shopUnlocked(s)) break;
      last = s.lastLevel;
    }
    return last;
  }
}

class RestaurantNotifier extends Notifier<RestaurantState> {
  static const _ownedKey = 'restaurant_owned';

  @override
  RestaurantState build() {
    final s = ref.read(storeProvider);
    return RestaurantState(
      best: {
        for (final k in s.keys.where((k) => k.startsWith('stars_')))
          int.parse(k.substring(6)): s.get<int>(k) ?? 0,
      },
      owned: (s.getStringList(_ownedKey) ?? const []).toSet(),
    );
  }

  /// Keeps only the best result per level. Returns the stars gained.
  int recordStars(int level, int stars) {
    final before = state.bestStars(level);
    if (stars <= before) return 0;
    state = RestaurantState(
        best: {...state.best, level: stars}, owned: state.owned);
    ref.read(storeProvider).put('stars_$level', stars);
    return stars - before;
  }

  void _own(String id) {
    state = RestaurantState(best: state.best, owned: {...state.owned, id});
    ref.read(storeProvider).put(_ownedKey, state.owned.toList());
  }

  bool buyShop(ShopDef s) {
    final free = ref.read(settingsProvider).testMode;
    if (state.shopUnlocked(s) || (!free && state.available < s.unlockCost)) {
      return false;
    }
    _own('shop:${s.id}');
    return true;
  }

  /// Returns true when the purchase happened. Finishing the last decoration
  /// of a shop pays out coins plus a free Chopsticks.
  bool buyDecor(ShopDef s, DecorDef d) {
    if (!state.shopUnlocked(s) ||
        state.decorOwned(s, d) ||
        (!ref.read(settingsProvider).testMode && state.available < d.cost)) {
      return false;
    }
    _own('decor:${s.id}:${d.id}');
    if (state.shopComplete(s)) {
      final wallet = ref.read(walletProvider.notifier);
      wallet.earn(Restaurant.completeCoins);
      wallet.grant(Booster.chopsticks, 1);
    }
    return true;
  }

  void reset() {
    final s = ref.read(storeProvider);
    for (final k in s.keys.where((k) => k.startsWith('stars_')).toList()) {
      s.remove(k);
    }
    s.remove(_ownedKey);
    state = const RestaurantState();
  }
}

final restaurantProvider =
    NotifierProvider<RestaurantNotifier, RestaurantState>(
        RestaurantNotifier.new);
