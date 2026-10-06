import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Stars earned from levels are spent here on new restaurants and their
/// decorations. Spent stars are derived from what is owned, so there is no
/// counter to drift out of sync.
abstract final class Restaurant {
  static const shops = [
    ShopDef('tsukiji', '🐟', 1, 15, 0, [
      DecorDef('lantern', '🏮', 3),
      DecorDef('table', '🪑', 5),
      DecorDef('sign', '🪧', 8),
    ]),
    ShopDef('osaka', '🍢', 16, 30, 12, [
      DecorDef('lantern', '🏮', 4),
      DecorDef('table', '🪑', 6),
      DecorDef('sign', '🪧', 10),
    ]),
  ];

  static const completeCoins = 100;

  /// Bumped on every change so screens can rebuild with one listener.
  static final revision = ValueNotifier<int>(0);

  static final Map<int, int> _best = {};
  static final Set<String> _owned = {};

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _best.clear();
    for (final k in prefs.getKeys().where((k) => k.startsWith('stars_'))) {
      _best[int.parse(k.substring(6))] = prefs.getInt(k) ?? 0;
    }
    _owned
      ..clear()
      ..addAll(prefs.getStringList('restaurant_owned') ?? const []);
    revision.value++;
  }

  static int get earned => _best.values.fold(0, (a, b) => a + b);

  static int get spent {
    var total = 0;
    for (final s in shops) {
      if (shopUnlocked(s)) total += s.unlockCost;
      for (final d in s.decor) {
        if (decorOwned(s, d)) total += d.cost;
      }
    }
    return total;
  }

  static int get available => earned - spent;

  static int bestStars(int level) => _best[level] ?? 0;

  /// Keeps only the best result per level. Returns the stars gained.
  static Future<int> recordStars(int level, int stars) async {
    final before = bestStars(level);
    if (stars <= before) return 0;
    _best[level] = stars;
    revision.value++;
    await (await SharedPreferences.getInstance()).setInt('stars_$level', stars);
    return stars - before;
  }

  static bool shopUnlocked(ShopDef s) =>
      s.unlockCost == 0 || _owned.contains('shop:${s.id}');

  static bool decorOwned(ShopDef s, DecorDef d) =>
      _owned.contains('decor:${s.id}:${d.id}');

  static bool shopComplete(ShopDef s) =>
      s.decor.every((d) => decorOwned(s, d));

  /// Highest level the player may enter: the end of the last shop reached
  /// without skipping a locked one.
  static int get maxPlayableLevel {
    var last = 0;
    for (final s in shops) {
      if (!shopUnlocked(s)) break;
      last = s.lastLevel;
    }
    return last;
  }

  static ShopDef? shopOfLevel(int level) {
    for (final s in shops) {
      if (level >= s.firstLevel && level <= s.lastLevel) return s;
    }
    return null;
  }

  static Future<bool> buyShop(ShopDef s) async {
    if (shopUnlocked(s) || available < s.unlockCost) return false;
    _owned.add('shop:${s.id}');
    await _save();
    return true;
  }

  /// Returns true when the purchase happened. Finishing the last decoration
  /// of a shop pays out coins plus a free Chopsticks.
  static Future<bool> buyDecor(ShopDef s, DecorDef d) async {
    if (!shopUnlocked(s) || decorOwned(s, d) || available < d.cost) {
      return false;
    }
    _owned.add('decor:${s.id}:${d.id}');
    if (shopComplete(s)) {
      Wallet.earn(completeCoins);
      Wallet.grant(Booster.chopsticks, 1);
    }
    await _save();
    return true;
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in prefs.getKeys().where((k) => k.startsWith('stars_'))) {
      await prefs.remove(k);
    }
    await prefs.remove('restaurant_owned');
    _best.clear();
    _owned.clear();
    revision.value++;
  }

  static Future<void> _save() async {
    revision.value++;
    await (await SharedPreferences.getInstance())
        .setStringList('restaurant_owned', _owned.toList());
  }
}
