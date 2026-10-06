import 'dart:ui' show Color;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../core/game_engine.dart';
import '../core/level.dart';
import '../core/piece.dart';
import '../services/audio.dart';
import '../services/wallet.dart';
import 'board_component.dart';

/// What the Flutter HUD needs; refreshed after every turn.
@immutable
class HudState {
  const HudState({
    required this.movesLeft,
    required this.score,
    required this.goals,
    required this.status,
    required this.stars,
    this.reward = 0,
  });

  final int movesLeft;
  final int score;
  final List<GoalProgress> goals;
  final GameStatus status;
  final int stars;

  /// Coins granted for this win (0 until won).
  final int reward;
}

class SushiGame extends FlameGame {
  SushiGame(
      {required this.level, required this.wallet, this.starters = const []})
      : _engine = GameEngine(level, seed: _seed(level)) {
    _placeStarters();
    hud = ValueNotifier(_snapshot());
  }

  /// Build with `--dart-define=DETERMINISTIC_SEED=true` to replay each level's
  /// JSON `seed` exactly (debugging, bot runs). Players get a fresh board.
  static const _deterministic = bool.fromEnvironment('DETERMINISTIC_SEED');

  static int _seed(LevelConfig level) =>
      _deterministic ? level.seed : DateTime.now().microsecondsSinceEpoch;

  /// Chef's cheer for the latest turn; null when there is none to show.
  final praise = ValueNotifier<({String text, int n})?>(null);
  int _praiseCount = 0;

  /// Booster waiting for a tap on the board (chopsticks / free swap).
  final armed = ValueNotifier<Booster?>(null);

  bool _rewarded = false;
  bool _lifeCharged = false;
  int _reward = 0;

  final LevelConfig level;
  final WalletNotifier wallet;

  /// Starter boosters picked before the level; each is spent from the wallet
  /// when the board is first laid out.
  final List<Booster> starters;

  GameEngine _engine;
  BoardComponent? _board;
  late final ValueNotifier<HudState> hud;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async => _mountBoard();

  void _placeStarters() {
    for (final b in starters) {
      if (!b.isStarter || wallet.count(b) <= 0) continue;
      final type = b == Booster.starterKnife
          ? (_engine.rng.nextBool()
              ? SpecialType.knifeRow
              : SpecialType.knifeCol)
          : SpecialType.wasabi;
      if (_engine.placeStarter(type)) wallet.consume(b);
    }
  }

  void restart() {
    _board?.removeFromParent();
    _engine = GameEngine(level, seed: _seed(level));
    praise.value = null;
    armed.value = null;
    _rewarded = false;
    _lifeCharged = false;
    _reward = 0;
    _mountBoard();
    _sync();
  }

  void _mountBoard() {
    final b = BoardComponent(
      engine: _engine,
      onTurnFinished: _sync,
      onPraise: _praise,
      armed: armed,
      onSpendBooster: wallet.consume,
    );
    _board = b;
    add(b);
  }

  void _sync() {
    if (_engine.status == GameStatus.won && !_rewarded) {
      _rewarded = true;
      _reward = 10 * _engine.stars;
      wallet.earn(_reward);
      Audio.play(Sfx.win);
    } else if (_engine.status == GameStatus.lost && !_lifeCharged) {
      _lifeCharged = true;
      wallet.loseLife();
      Audio.play(Sfx.lose);
    }
    hud.value = _snapshot();
  }

  /// Booster button pressed. Shuffle fires at once; the others arm the
  /// board and fire on the next tap(s).
  void tapBooster(Booster b) {
    if (_engine.status != GameStatus.playing) return;
    switch (b) {
      case Booster.shuffle:
        _board?.useShuffle();
      case Booster.chopsticks || Booster.freeSwap:
        armed.value = armed.value == b || !wallet.canUse(b) ? null : b;
      case Booster.extraMoves || Booster.starterKnife || Booster.starterWasabi:
        break;
    }
  }

  /// Buys +5 moves, e.g. from the "out of moves" screen. Gives the life back.
  bool buyExtraMoves() {
    if (_engine.status == GameStatus.won ||
        !wallet.consume(Booster.extraMoves)) {
      return false;
    }
    _engine.addMoves(Wallet.extraMovesAmount);
    if (_lifeCharged) {
      wallet.refundLife();
      _lifeCharged = false;
    }
    _sync();
    return true;
  }

  void _praise(String text) => praise.value = (text: text, n: ++_praiseCount);

  HudState _snapshot() => HudState(
        movesLeft: _engine.movesLeft,
        score: _engine.score,
        goals: _engine.goals,
        status: _engine.status,
        stars: _engine.stars,
        reward: _reward,
      );
}
