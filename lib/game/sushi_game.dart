import 'dart:ui' show Color;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../core/game_engine.dart';
import '../core/level.dart';
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
  });

  final int movesLeft;
  final int score;
  final List<GoalProgress> goals;
  final GameStatus status;
  final int stars;
}

class SushiGame extends FlameGame {
  SushiGame({required this.level})
      : _engine = GameEngine(level, seed: _seed(level)) {
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

  final LevelConfig level;
  GameEngine _engine;
  BoardComponent? _board;
  late final ValueNotifier<HudState> hud;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async => _mountBoard();

  void restart() {
    _board?.removeFromParent();
    _engine = GameEngine(level, seed: _seed(level));
    praise.value = null;
    _mountBoard();
    _sync();
  }

  void _mountBoard() {
    final b = BoardComponent(
        engine: _engine, onTurnFinished: _sync, onPraise: _praise);
    _board = b;
    add(b);
  }

  void _sync() => hud.value = _snapshot();

  void _praise(String text) => praise.value = (text: text, n: ++_praiseCount);

  HudState _snapshot() => HudState(
        movesLeft: _engine.movesLeft,
        score: _engine.score,
        goals: _engine.goals,
        status: _engine.status,
        stars: _engine.stars,
      );
}
