import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'store.dart';

enum Booster {
  extraMoves,
  chopsticks,
  freeSwap,
  shuffle,

  /// Pre-level boosters: a special piece is placed on the board at the start.
  starterKnife,
  starterWasabi;

  bool get isStarter => this == starterKnife || this == starterWasabi;
}

/// Wallet constants and pricing.
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
    Booster.starterKnife: 25,
    Booster.starterWasabi: 25,
  };

  /// Shop bundle: buying this many at once is [bundleDiscount] cheaper.
  static const bundleSize = 3;
  static const bundleDiscount = 0.8;

  /// Coins for buying [qty] of [b] in the shop.
  static int price(Booster b, int qty) => qty >= bundleSize
      ? (cost[b]! * qty * bundleDiscount).round()
      : cost[b]! * qty;
}

@immutable
class WalletState {
  const WalletState({
    required this.lives,
    required this.coins,
    this.stock = const {},
    this.since,
  });

  final int lives;
  final int coins;
  final Map<Booster, int> stock;

  /// When the current regeneration cycle started; null while lives are full.
  final DateTime? since;

  int count(Booster b) => stock[b] ?? 0;

  bool canUse(Booster b) => count(b) > 0 || coins >= Wallet.cost[b]!;

  /// Time until the next life at [now], or null when full.
  Duration? nextLifeIn(DateTime now) {
    final from = since;
    if (from == null || lives >= Wallet.maxLives) return null;
    final left = from.add(Wallet.lifeEvery).difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  WalletState copyWith(
          {int? lives,
          int? coins,
          Map<Booster, int>? stock,
          DateTime? since,
          bool clearSince = false}) =>
      WalletState(
        lives: lives ?? this.lives,
        coins: coins ?? this.coins,
        stock: stock ?? this.stock,
        since: clearSince ? null : since ?? this.since,
      );
}

/// Lives, coins and booster stock. Lives regenerate lazily: the clock only
/// matters when someone looks, so no background timer is needed ([tick] is
/// called by whatever shows the countdown).
class WalletNotifier extends Notifier<WalletState> {
  DateTime _now() => ref.read(clockProvider)();

  @override
  WalletState build() {
    final s = ref.read(storeProvider);
    final ms = s.get<int>('lives_since');
    final loaded = WalletState(
      lives: s.get<int>('lives') ?? Wallet.maxLives,
      coins: s.get<int>('coins') ?? Wallet.startingCoins,
      since: ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
      stock: {
        for (final b in Booster.values) b: s.get<int>('booster_${b.name}') ?? 0,
      },
    );
    return _ticked(loaded);
  }

  WalletState _ticked(WalletState w) {
    final from = w.since;
    if (from == null || w.lives >= Wallet.maxLives) return w;
    final earned =
        _now().difference(from).inSeconds ~/ Wallet.lifeEvery.inSeconds;
    if (earned <= 0) return w;
    final lives = (w.lives + earned).clamp(0, Wallet.maxLives);
    return lives >= Wallet.maxLives
        ? w.copyWith(lives: lives, clearSince: true)
        : w.copyWith(lives: lives, since: from.add(Wallet.lifeEvery * earned));
  }

  /// Applies any lives earned since the last call. Cheap; call it freely
  /// (but not from inside a build).
  void tick() {
    final next = _ticked(state);
    if (identical(next, state)) return;
    _set(next);
  }

  Duration? get nextLifeIn => state.nextLifeIn(_now());

  /// Stock and affordability for non-widget callers (the game).
  int count(Booster b) => state.count(b);
  bool canUse(Booster b) => state.canUse(b);

  void loseLife() {
    tick();
    if (state.lives <= 0) return;
    _set(state.copyWith(
      lives: state.lives - 1,
      since: state.lives >= Wallet.maxLives ? _now() : null,
    ));
  }

  /// Gives a life back (e.g. the player bought extra moves after losing).
  void refundLife() {
    if (state.lives >= Wallet.maxLives) return;
    final lives = state.lives + 1;
    _set(lives >= Wallet.maxLives
        ? state.copyWith(lives: lives, clearSince: true)
        : state.copyWith(lives: lives));
  }

  bool refillLifeWithCoins() {
    if (state.coins < Wallet.lifeRefillCost) return false;
    _set(state.copyWith(coins: state.coins - Wallet.lifeRefillCost));
    refundLife();
    return true;
  }

  void earn(int amount) => _set(state.copyWith(coins: state.coins + amount));

  /// Adds free boosters to the stock (e.g. a finished restaurant's reward).
  void grant(Booster b, int n) =>
      _set(state.copyWith(stock: {...state.stock, b: state.count(b) + n}));

  /// Buys [qty] boosters into the stock; false when the coins don't stretch.
  bool buy(Booster b, int qty) {
    final p = Wallet.price(b, qty);
    if (qty <= 0 || state.coins < p) return false;
    _set(state.copyWith(
        coins: state.coins - p,
        stock: {...state.stock, b: state.count(b) + qty}));
    return true;
  }

  /// Uses one from stock, or pays coins when the stock is empty.
  bool consume(Booster b) {
    if (state.count(b) > 0) {
      _set(state.copyWith(stock: {...state.stock, b: state.count(b) - 1}));
    } else if (state.coins >= Wallet.cost[b]!) {
      _set(state.copyWith(coins: state.coins - Wallet.cost[b]!));
    } else {
      return false;
    }
    return true;
  }

  /// Publishes [next] and writes only the keys that changed.
  void _set(WalletState next) {
    final prev = state;
    state = next;
    final s = ref.read(storeProvider);
    if (next.lives != prev.lives) s.put('lives', next.lives);
    if (next.coins != prev.coins) s.put('coins', next.coins);
    final since = next.since;
    if (since != prev.since) {
      if (since == null) {
        s.remove('lives_since');
      } else {
        s.put('lives_since', since.millisecondsSinceEpoch);
      }
    }
    for (final b in Booster.values) {
      if (next.count(b) != prev.count(b)) {
        s.put('booster_${b.name}', next.count(b));
      }
    }
  }
}

final walletProvider =
    NotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);
