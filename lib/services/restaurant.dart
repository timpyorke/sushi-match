import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/piece.dart';
import '../core/settings.dart';
import 'store.dart';
import 'wallet.dart';

/// How the shop groups furniture. [dining] pieces also add a display slot
/// for sushi (see [Restaurant.slotCount]).
enum FurnitureCategory { storefront, dining, charm, ambience }

/// A piece of furniture for the player's restaurant, bought once with stars.
/// Its [appeal] makes customers come sooner and pay more for the sushi on
/// display (see [RestaurantState.priceBoost] and [RestaurantState.visitEvery]).
class FurnitureDef {
  const FurnitureDef(this.id, this.category, this.cost, this.appeal);
  final String id;
  final FurnitureCategory category;
  final int cost;
  final int appeal;

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
    FurnitureDef('lantern', FurnitureCategory.ambience, 2, 2),
    FurnitureDef('stool', FurnitureCategory.dining, 4, 2),
    FurnitureDef('noren', FurnitureCategory.storefront, 7, 3),
    FurnitureDef('sign', FurnitureCategory.storefront, 10, 3),
    FurnitureDef('plant', FurnitureCategory.charm, 15, 4),
    FurnitureDef('luckycat', FurnitureCategory.charm, 20, 4),
    FurnitureDef('aquarium', FurnitureCategory.charm, 28, 5),
    FurnitureDef('conveyor', FurnitureCategory.dining, 38, 5),
    FurnitureDef('kadomatsu', FurnitureCategory.storefront, 50, 6),
    FurnitureDef('taiko', FurnitureCategory.ambience, 62, 6),
    FurnitureDef('sake', FurnitureCategory.dining, 74, 8),
    FurnitureDef('trophy', FurnitureCategory.ambience, 90, 10),
  ];

  static Iterable<FurnitureDef> inCategory(FurnitureCategory c) =>
      furniture.where((f) => f.category == c);

  /// Coins one customer pays for a piece of sushi before the appeal bonus.
  static const basePrice = {
    PieceKind.kappa: 3,
    PieceKind.tamago: 4,
    PieceKind.ika: 5,
    PieceKind.tako: 5,
    PieceKind.salmon: 6,
    PieceKind.ebi: 7,
    PieceKind.maguro: 8,
    PieceKind.unagi: 9,
    PieceKind.hotate: 9,
    PieceKind.ikura: 10,
  };

  /// Display slots at the start, one more for each dining furniture bought.
  static const baseSlots = 3;
  static final maxSlots =
      baseSlots + inCategory(FurnitureCategory.dining).length;

  /// A customer comes this often with no furniture, and this often at best.
  static const slowestVisit = 60;
  static const fastestVisit = 25;

  /// Sushi earned by winning a level: one more than the stars it scored.
  static int sushiReward(int stars) => stars + 1;

  /// The sushi a won level pays out: its own palette, rotated by level
  /// number so neighbouring levels favour different kinds.
  static List<PieceKind> rewardFor(
      int level, int stars, List<PieceKind> palette) {
    if (palette.isEmpty) return const [];
    return [
      for (var i = 0; i < sushiReward(stars); i++)
        palette[(level + i) % palette.length],
    ];
  }

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

/// Winning levels earns stars (spent on furniture) and sushi (put on the
/// display shelf). Customers come by and buy what is on the shelf, paying
/// into the till. Spent stars are derived from what is owned, and customer
/// visits are computed from the clock when asked (like lives), so there is
/// no counter to drift out of sync and no background timer.
@immutable
class RestaurantState {
  const RestaurantState(
      {this.best = const {},
      this.owned = const {},
      this.stock = const {},
      this.shelf = const [],
      this.banked = 0,
      this.since});

  /// Best star count per level.
  final Map<int, int> best;

  /// Ids of the furniture bought.
  final Set<String> owned;

  /// Sushi won and not yet on display.
  final Map<PieceKind, int> stock;

  /// The display slots; null is an empty slot and only the first [slotCount]
  /// can be used.
  final List<PieceKind?> shelf;

  /// Coins from sold sushi, waiting in the till.
  final int banked;

  /// When the customer now on their way started walking in; null while the
  /// shelf is empty.
  final DateTime? since;

  int get earned => best.values.fold(0, (a, b) => a + b);

  int get spent =>
      Restaurant.furniture.where(isOwned).fold(0, (total, f) => total + f.cost);

  int get available => earned - spent;

  int bestStars(int level) => best[level] ?? 0;

  bool isOwned(FurnitureDef f) => owned.contains(f.id);

  bool get fullyFurnished => Restaurant.furniture.every(isOwned);

  int ownedIn(FurnitureCategory c) =>
      Restaurant.inCategory(c).where(isOwned).length;

  /// Usable display slots.
  int get slotCount => Restaurant.baseSlots + ownedIn(FurnitureCategory.dining);

  PieceKind? slot(int i) => i < shelf.length ? shelf[i] : null;

  int get placed => shelf.take(slotCount).whereType<PieceKind>().length;

  int get stockTotal => stock.values.fold(0, (a, b) => a + b);

  int count(PieceKind k) => stock[k] ?? 0;

  /// Total appeal of the furniture bought.
  int get appeal =>
      Restaurant.furniture.where(isOwned).fold(0, (t, f) => t + f.appeal);

  /// Percent added to every sale.
  int get priceBoost => appeal * 2;

  /// What one customer pays for [k] with this furniture.
  int price(PieceKind k) =>
      ((Restaurant.basePrice[k] ?? 1) * (100 + priceBoost) / 100).round();

  /// Seconds between customers: furniture speeds them up.
  int get visitEvery => (Restaurant.slowestVisit - appeal * 6 ~/ 10)
      .clamp(Restaurant.fastestVisit, Restaurant.slowestVisit);

  /// This state after the customers who came by up to [now] bought their
  /// sushi, one per [visitEvery], from the first slot on.
  RestaurantState settled(DateTime now) {
    final from = since;
    if (from == null) return this;
    if (placed == 0) return copyWith(clearSince: true);
    final visits = math.max(0, now.difference(from).inSeconds) ~/ visitEvery;
    if (visits == 0) return this;
    final next = [...shelf];
    var coins = 0, sold = 0;
    for (var i = 0; i < slotCount && sold < visits; i++) {
      final k = next[i];
      if (k == null) continue;
      coins += price(k);
      next[i] = null;
      sold++;
    }
    final left = next.take(slotCount).any((k) => k != null);
    return copyWith(
      shelf: next,
      banked: banked + coins,
      since: left ? from.add(Duration(seconds: visitEvery * sold)) : null,
      clearSince: !left,
    );
  }

  RestaurantState copyWith(
          {Map<int, int>? best,
          Set<String>? owned,
          Map<PieceKind, int>? stock,
          List<PieceKind?>? shelf,
          int? banked,
          DateTime? since,
          bool clearSince = false}) =>
      RestaurantState(
        best: best ?? this.best,
        owned: owned ?? this.owned,
        stock: stock ?? this.stock,
        shelf: shelf ?? this.shelf,
        banked: banked ?? this.banked,
        since: clearSince ? null : since ?? this.since,
      );
}

class RestaurantNotifier extends Notifier<RestaurantState> {
  static const _ownedKey = 'restaurant_owned';
  static const _bankedKey = 'restaurant_banked';
  static const _sinceKey = 'restaurant_since';
  static const _shelfKey = 'restaurant_shelf';
  static String _stockKey(PieceKind k) => 'sushi_${k.name}';

  DateTime _now() => ref.read(clockProvider)();

  @override
  RestaurantState build() {
    final s = ref.read(storeProvider);
    final ids = {for (final f in Restaurant.furniture) f.id};
    final ms = s.get<int>(_sinceKey);
    final saved = s.getStringList(_shelfKey) ?? const [];
    final kinds = PieceKind.values.asNameMap();
    final loaded = RestaurantState(
      best: {
        for (final k in s.keys.where((k) => k.startsWith('stars_')))
          int.parse(k.substring(6)): s.get<int>(k) ?? 0,
      },
      // Saves from the old one-restaurant-per-region design hold
      // 'shop:…'/'decor:…' entries; dropping them refunds their stars.
      owned:
          (s.getStringList(_ownedKey) ?? const []).where(ids.contains).toSet(),
      stock: {
        for (final k in PieceKind.values)
          if ((s.get<int>(_stockKey(k)) ?? 0) > 0) k: s.get<int>(_stockKey(k))!,
      },
      shelf: [
        for (var i = 0; i < Restaurant.maxSlots; i++)
          i < saved.length ? kinds[saved[i]] : null,
      ],
      banked: s.get<int>(_bankedKey) ?? 0,
      since: ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
    );
    return loaded.settled(_now());
  }

  /// Keeps only the best result per level. Returns the stars gained.
  int recordStars(int level, int stars) {
    final before = state.bestStars(level);
    if (stars <= before) return 0;
    state = state.copyWith(best: {...state.best, level: stars});
    ref.read(storeProvider).put('stars_$level', stars);
    return stars - before;
  }

  /// Books the sales customers have made by now. Cheap; call it freely (but
  /// not from inside a build).
  void settle() {
    final next = state.settled(_now());
    if (!identical(next, state)) _set(next);
  }

  /// The state as customers have left it by now, without changing anything.
  RestaurantState view() => state.settled(_now());

  /// Coins waiting in the till right now.
  int till() => view().banked;

  /// Adds won sushi to the stock.
  void grantSushi(Iterable<PieceKind> kinds) {
    final stock = {...state.stock};
    for (final k in kinds) {
      stock[k] = (stock[k] ?? 0) + 1;
    }
    _set(state.copyWith(stock: stock));
  }

  /// Puts a sushi from the stock on [slot]. False when the slot is locked or
  /// taken, or none is in stock.
  bool place(PieceKind kind, int slot) {
    settle();
    if (slot < 0 || slot >= state.slotCount) return false;
    if (state.slot(slot) != null || state.count(kind) <= 0) return false;
    final shelf = _shelfOf(state);
    shelf[slot] = kind;
    _set(state.copyWith(
      shelf: shelf,
      stock: {...state.stock, kind: state.count(kind) - 1},
      // The first sushi on an empty shelf starts the wait for a customer.
      since: state.since ?? _now(),
    ));
    return true;
  }

  /// Takes the sushi on [slot] back into the stock.
  bool take(int slot) {
    settle();
    final kind = state.slot(slot);
    if (kind == null) return false;
    final shelf = _shelfOf(state)..[slot] = null;
    _set(state.copyWith(
      shelf: shelf,
      stock: {...state.stock, kind: state.count(kind) + 1},
      clearSince: !shelf.take(state.slotCount).any((k) => k != null),
    ));
    return true;
  }

  List<PieceKind?> _shelfOf(RestaurantState s) => [
        for (var i = 0; i < Restaurant.maxSlots; i++) s.slot(i),
      ];

  /// Returns true when the purchase happened.
  bool buyFurniture(FurnitureDef f) {
    if (state.isOwned(f) ||
        (!ref.read(settingsProvider).testMode && state.available < f.cost)) {
      return false;
    }
    // Sales so far were made at the old prices.
    settle();
    _set(state.copyWith(owned: {...state.owned, f.id}));
    return true;
  }

  /// Moves the till's coins into the wallet. Returns how many.
  int collect() {
    settle();
    final coins = state.banked;
    if (coins <= 0) return 0;
    ref.read(walletProvider.notifier).earn(coins);
    _set(state.copyWith(banked: 0));
    return coins;
  }

  void _set(RestaurantState next) {
    final prev = state;
    state = next;
    final s = ref.read(storeProvider);
    if (next.owned != prev.owned) s.put(_ownedKey, next.owned.toList());
    if (next.banked != prev.banked) s.put(_bankedKey, next.banked);
    final since = next.since;
    if (since == null) {
      s.remove(_sinceKey);
    } else {
      s.put(_sinceKey, since.millisecondsSinceEpoch);
    }
    s.put(_shelfKey, [for (final k in next.shelf) k?.name ?? '']);
    for (final k in PieceKind.values) {
      if (next.count(k) != prev.count(k)) s.put(_stockKey(k), next.count(k));
    }
  }

  void reset() {
    final s = ref.read(storeProvider);
    for (final k in s.keys.where((k) => k.startsWith('stars_')).toList()) {
      s.remove(k);
    }
    s.remove(_ownedKey);
    s.remove(_bankedKey);
    s.remove(_sinceKey);
    s.remove(_shelfKey);
    for (final k in PieceKind.values) {
      s.remove(_stockKey(k));
    }
    state = const RestaurantState();
  }
}

final restaurantProvider =
    NotifierProvider<RestaurantNotifier, RestaurantState>(
        RestaurantNotifier.new);
