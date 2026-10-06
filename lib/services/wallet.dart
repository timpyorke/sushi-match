import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Booster { extraMoves, chopsticks, freeSwap, shuffle }

/// Lives, coins and booster stock. Lives regenerate lazily: the clock only
/// matters when someone looks, so no background timer is needed.
abstract final class Wallet {
  static const maxLives = 5;
  static const lifeEvery = Duration(minutes: 30);
  static const startingCoins = 100;
  static const lifeRefillCost = 30;
  static const extraMovesAmount = 5;

  /// Coins charged when a booster is used with none in stock.
  static const cost = {
    Booster.extraMoves: 40,
    Booster.chopsticks: 15,
    Booster.freeSwap: 15,
    Booster.shuffle: 10,
  };

  static final lives = ValueNotifier<int>(maxLives);
  static final coins = ValueNotifier<int>(startingCoins);
  static final stock = ValueNotifier<Map<Booster, int>>(const {});

  /// Injectable for tests.
  static DateTime Function() clock = DateTime.now;

  /// When the current regeneration cycle started; null while lives are full.
  static DateTime? _since;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    lives.value = prefs.getInt('lives') ?? maxLives;
    coins.value = prefs.getInt('coins') ?? startingCoins;
    final ms = prefs.getInt('lives_since');
    _since = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    stock.value = {
      for (final b in Booster.values) b: prefs.getInt('booster_${b.name}') ?? 0,
    };
    tick();
  }

  /// Applies any lives earned since the last call. Cheap; call it freely.
  static void tick() {
    final from = _since;
    if (from == null || lives.value >= maxLives) return;
    final earned = clock().difference(from).inSeconds ~/ lifeEvery.inSeconds;
    if (earned <= 0) return;
    lives.value = (lives.value + earned).clamp(0, maxLives);
    _since = lives.value >= maxLives ? null : from.add(lifeEvery * earned);
    _save();
  }

  /// Time until the next life, or null when full.
  static Duration? get nextLifeIn {
    tick();
    final from = _since;
    if (from == null || lives.value >= maxLives) return null;
    final left = from.add(lifeEvery).difference(clock());
    return left.isNegative ? Duration.zero : left;
  }

  static void loseLife() {
    tick();
    if (lives.value <= 0) return;
    if (lives.value >= maxLives) _since = clock();
    lives.value--;
    _save();
  }

  /// Gives a life back (e.g. the player bought extra moves after losing).
  static void refundLife() {
    if (lives.value >= maxLives) return;
    lives.value++;
    if (lives.value >= maxLives) _since = null;
    _save();
  }

  static bool refillLifeWithCoins() {
    if (coins.value < lifeRefillCost) return false;
    coins.value -= lifeRefillCost;
    refundLife();
    return true;
  }

  static void earn(int amount) {
    coins.value += amount;
    _save();
  }

  /// Adds free boosters to the stock (e.g. a finished restaurant's reward).
  static void grant(Booster b, int n) {
    stock.value = {...stock.value, b: count(b) + n};
    _save();
  }

  static int count(Booster b) => stock.value[b] ?? 0;

  static bool canUse(Booster b) => count(b) > 0 || coins.value >= cost[b]!;

  /// Uses one from stock, or pays coins when the stock is empty.
  static bool consume(Booster b) {
    if (count(b) > 0) {
      stock.value = {...stock.value, b: count(b) - 1};
    } else if (coins.value >= cost[b]!) {
      coins.value -= cost[b]!;
    } else {
      return false;
    }
    _save();
    return true;
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lives', lives.value);
    await prefs.setInt('coins', coins.value);
    final since = _since;
    if (since == null) {
      await prefs.remove('lives_since');
    } else {
      await prefs.setInt('lives_since', since.millisecondsSinceEpoch);
    }
    for (final b in Booster.values) {
      await prefs.setInt('booster_${b.name}', count(b));
    }
  }
}
