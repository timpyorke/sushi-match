import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import 'store.dart';
import 'wallet.dart';

/// A piece of furniture for the player's restaurant: bought once with stars,
/// it draws more customers, who pay [coinsPerHour] into the till.
class FurnitureDef {
  const FurnitureDef(this.id, this.cost, this.coinsPerHour);
  final String id;
  final int cost;
  final int coinsPerHour;

  String get nameKey => 'furn_$id';
}

/// One region of the level map: a block of levels with its own name, map
/// band and music. Regions open by clearing levels, not by buying.
class ShopDef {
  const ShopDef(this.id, this.firstLevel, this.lastLevel);
  final String id;
  final int firstLevel;
  final int lastLevel;

  String get nameKey => 'shop_$id';
}

/// Map regions, the furniture catalogue and the till's constants.
///
/// Pacing (a mid-skill bot averages ~2.2 stars a level, ~450 over 205
/// levels): the furniture costs 400 stars in all, so a player furnishes the
/// whole restaurant near the end of the map, sooner by replaying for 3 stars.
abstract final class Restaurant {
  static const shops = [
    ShopDef('tsukiji', 1, 15),
    ShopDef('osaka', 16, 30),
    ShopDef('kyoto', 31, 45),
    ShopDef('hokkaido', 46, 60),
    ShopDef('fukuoka', 61, 75),
    ShopDef('okinawa', 76, 90),
    ShopDef('omakase', 91, 100),
    ShopDef('nagoya', 101, 115),
    ShopDef('hiroshima', 116, 130),
    ShopDef('kanazawa', 131, 145),
    ShopDef('sendai', 146, 160),
    ShopDef('kobe', 161, 175),
    ShopDef('nara', 176, 190),
    ShopDef('ginza', 191, 205),
  ];

  /// Cheapest first; the scene places each by id.
  static const furniture = [
    FurnitureDef('lantern', 2, 2),
    FurnitureDef('stool', 4, 2),
    FurnitureDef('noren', 7, 3),
    FurnitureDef('sign', 10, 3),
    FurnitureDef('plant', 15, 4),
    FurnitureDef('luckycat', 20, 4),
    FurnitureDef('aquarium', 28, 5),
    FurnitureDef('conveyor', 38, 5),
    FurnitureDef('kadomatsu', 50, 6),
    FurnitureDef('taiko', 62, 6),
    FurnitureDef('sake', 74, 8),
    FurnitureDef('trophy', 90, 10),
  ];

  /// The till stops filling after this long, so coming back pays off but
  /// staying away does not pay more.
  static const tillHours = 6;

  /// Number of levels in the game: the end of the last region. To add
  /// levels, extend the last shop or append a new one (see
  /// docs/adding-levels.md).
  static int get totalLevels => shops.last.lastLevel;

  static ShopDef? shopOfLevel(int level) {
    for (final s in shops) {
      if (level >= s.firstLevel && level <= s.lastLevel) return s;
    }
    return null;
  }
}

/// Stars earned from levels buy furniture; furniture brings customers whose
/// coins collect in the till. Spent stars are derived from what is owned,
/// and the till is computed from the clock when asked (like lives), so
/// there is no counter to drift out of sync and no background timer.
@immutable
class RestaurantState {
  const RestaurantState(
      {this.best = const {},
      this.owned = const {},
      this.banked = 0,
      this.since});

  /// Best star count per level.
  final Map<int, int> best;

  /// Ids of the furniture bought.
  final Set<String> owned;

  /// Till coins earned at an earlier, lower rate (before the last purchase).
  final int banked;

  /// When the till last started filling at the current rate; null before
  /// the first piece of furniture.
  final DateTime? since;

  int get earned => best.values.fold(0, (a, b) => a + b);

  int get spent =>
      Restaurant.furniture.where(isOwned).fold(0, (total, f) => total + f.cost);

  int get available => earned - spent;

  int bestStars(int level) => best[level] ?? 0;

  bool isOwned(FurnitureDef f) => owned.contains(f.id);

  bool get fullyFurnished => Restaurant.furniture.every(isOwned);

  /// What the customers pay per hour with the furniture bought so far.
  int get coinsPerHour => Restaurant.furniture
      .where(isOwned)
      .fold(0, (total, f) => total + f.coinsPerHour);

  int get tillCap => coinsPerHour * Restaurant.tillHours;

  /// Coins waiting in the till at [now].
  int till(DateTime now) {
    final from = since;
    if (from == null) return banked;
    final secs = math.max(0, now.difference(from).inSeconds);
    return math.min(tillCap, banked + secs * coinsPerHour ~/ 3600);
  }

  RestaurantState copyWith(
          {Map<int, int>? best,
          Set<String>? owned,
          int? banked,
          DateTime? since}) =>
      RestaurantState(
        best: best ?? this.best,
        owned: owned ?? this.owned,
        banked: banked ?? this.banked,
        since: since ?? this.since,
      );
}

class RestaurantNotifier extends Notifier<RestaurantState> {
  static const _ownedKey = 'restaurant_owned';
  static const _bankedKey = 'restaurant_banked';
  static const _sinceKey = 'restaurant_since';

  DateTime _now() => ref.read(clockProvider)();

  @override
  RestaurantState build() {
    final s = ref.read(storeProvider);
    final ids = {for (final f in Restaurant.furniture) f.id};
    final ms = s.get<int>(_sinceKey);
    return RestaurantState(
      best: {
        for (final k in s.keys.where((k) => k.startsWith('stars_')))
          int.parse(k.substring(6)): s.get<int>(k) ?? 0,
      },
      // Saves from the old one-restaurant-per-region design hold
      // 'shop:…'/'decor:…' entries; dropping them refunds their stars.
      owned:
          (s.getStringList(_ownedKey) ?? const []).where(ids.contains).toSet(),
      banked: s.get<int>(_bankedKey) ?? 0,
      since: ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
    );
  }

  /// Keeps only the best result per level. Returns the stars gained.
  int recordStars(int level, int stars) {
    final before = state.bestStars(level);
    if (stars <= before) return 0;
    state = state.copyWith(best: {...state.best, level: stars});
    ref.read(storeProvider).put('stars_$level', stars);
    return stars - before;
  }

  int till() => state.till(_now());

  /// Returns true when the purchase happened. The till keeps what it earned
  /// at the old rate and fills faster from now on.
  bool buyFurniture(FurnitureDef f) {
    if (state.isOwned(f) ||
        (!ref.read(settingsProvider).testMode && state.available < f.cost)) {
      return false;
    }
    final now = _now();
    _set(state.copyWith(
        owned: {...state.owned, f.id}, banked: state.till(now), since: now));
    return true;
  }

  /// Moves the till's coins into the wallet. Returns how many.
  int collect() {
    final now = _now();
    final coins = state.till(now);
    if (coins <= 0) return 0;
    ref.read(walletProvider.notifier).earn(coins);
    _set(state.copyWith(banked: 0, since: now));
    return coins;
  }

  void _set(RestaurantState next) {
    state = next;
    final s = ref.read(storeProvider);
    s.put(_ownedKey, next.owned.toList());
    s.put(_bankedKey, next.banked);
    final since = next.since;
    if (since != null) s.put(_sinceKey, since.millisecondsSinceEpoch);
  }

  void reset() {
    final s = ref.read(storeProvider);
    for (final k in s.keys.where((k) => k.startsWith('stars_')).toList()) {
      s.remove(k);
    }
    s.remove(_ownedKey);
    s.remove(_bankedKey);
    s.remove(_sinceKey);
    state = const RestaurantState();
  }
}

final restaurantProvider =
    NotifierProvider<RestaurantNotifier, RestaurantState>(
        RestaurantNotifier.new);
