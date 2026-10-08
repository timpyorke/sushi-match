import 'dart:ui' show Color;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../core/game_engine.dart';
import '../core/level.dart';
import '../core/piece.dart';
import '../services/analytics.dart';
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
    this.eventGain = 0,
  });

  final int movesLeft;
  final int score;
  final List<GoalProgress> goals;
  final GameStatus status;
  final int stars;

  /// Coins granted for this win (0 until won).
  final int reward;

  /// Weekly-event pieces cleared in this run so far (0 with no event).
  final int eventGain;
}

class SushiGame extends FlameGame {
  SushiGame(
      {required this.level,
      required this.wallet,
      this.starters = const [],
      this.eventKind,
      this.onEventGain,
      this.analytics})
      : _engine = GameEngine(level, seed: _seed(level)) {
    _placeStarters();
    hud = ValueNotifier(_snapshot());
    _logStart();
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

  /// Sushi the running weekly event counts; null when there is no event.
  final PieceKind? eventKind;

  /// Called with the event pieces cleared since the last call, once the run
  /// ends (win or loss).
  final void Function(int n)? onEventGain;
  int _eventPaid = 0;

  /// Receives level/booster events; null records nothing.
  final Analytics? analytics;
  int _attempt = 0;

  GameEngine _engine;
  BoardComponent? _board;
  late final ValueNotifier<HudState> hud;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async => _mountBoard();

  /// Starters are spent once, when the game is created. A restart gets a
  /// plain board: the player already paid for the first attempt.
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
    _eventPaid = 0;
    _mountBoard();
    _logStart();
    _sync();
  }

  void _mountBoard() {
    final b = BoardComponent(
      engine: _engine,
      onTurnFinished: _sync,
      onPraise: _praise,
      armed: armed,
      canSpendBooster: wallet.canUse,
      onSpendBooster: _spendBooster,
      onShuffle: () => analytics
          ?.log(AnalyticsEvent.shuffleTriggered, {'level_id': level.id}),
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
      _logEnd(AnalyticsEvent.levelWin);
    } else if (_engine.status == GameStatus.lost && !_lifeCharged) {
      _lifeCharged = true;
      wallet.loseLife();
      Audio.play(Sfx.lose);
      _logEnd(AnalyticsEvent.levelFail);
    }
    if (_engine.status != GameStatus.playing) _payEvent();
    hud.value = _snapshot();
  }

  void _logStart() {
    final a = analytics;
    if (a == null) return;
    _attempt = a.nextAttempt(level.id);
    a.log(AnalyticsEvent.levelStart,
        {'level_id': level.id, 'attempt_no': _attempt});
  }

  void _logEnd(String event) {
    var goal = 0, done = 0;
    for (final g in _engine.goals) {
      goal += g.goal.count;
      done += g.current.clamp(0, g.goal.count);
    }
    analytics?.log(event, {
      'level_id': level.id,
      'moves_left': _engine.movesLeft,
      'goal_progress': goal == 0 ? 100 : done * 100 ~/ goal,
      'attempt_no': _attempt,
    });
  }

  bool _spendBooster(Booster b) {
    if (!wallet.consume(b)) return false;
    analytics?.log(
        AnalyticsEvent.boosterUsed, {'booster': b.name, 'level_id': level.id});
    return true;
  }

  int get _eventTotal {
    final k = eventKind;
    return k == null ? 0 : _engine.collectedOf(k);
  }

  /// Hands the tally to the event once per finished run. Extra moves can
  /// reopen a lost run, so only the part not yet paid goes out.
  void _payEvent() {
    final n = _eventTotal - _eventPaid;
    if (n <= 0) return;
    _eventPaid += n;
    onEventGain?.call(n);
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
        eventGain: _eventPaid,
      );
}
