import 'dart:ui';

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
  SushiGame({required this.level}) : _engine = GameEngine(level) {
    hud = ValueNotifier(_snapshot());
  }

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
    // New seed each retry; pass level.seed instead to replay identically.
    _engine = GameEngine(level, seed: DateTime.now().microsecondsSinceEpoch);
    _mountBoard();
    _sync();
  }

  void _mountBoard() {
    final b = BoardComponent(engine: _engine, onTurnFinished: _sync);
    _board = b;
    add(b);
  }

  void _sync() => hud.value = _snapshot();

  HudState _snapshot() => HudState(
        movesLeft: _engine.movesLeft,
        score: _engine.score,
        goals: _engine.goals,
        status: _engine.status,
        stars: _engine.stars,
      );
}
