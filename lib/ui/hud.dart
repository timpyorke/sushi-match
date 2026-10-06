import 'package:flutter/material.dart';

import '../core/game_engine.dart';
import '../core/level.dart';
import '../game/piece_painter.dart';
import '../game/sushi_game.dart';

class HudBar extends StatelessWidget {
  const HudBar({super.key, required this.game});
  final SushiGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HudState>(
      valueListenable: game.hud,
      builder: (context, s, _) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(label: 'Moves', value: '${s.movesLeft}'),
            _Chip(label: 'Score', value: '${s.score}'),
            for (final g in s.goals)
              _Chip(
                label: _goalLabel(g.goal),
                value: '${g.current.clamp(0, g.goal.count)}/${g.goal.count}',
                color: g.goal.piece == null
                    ? null
                    : PiecePainter.colors[g.goal.piece!],
                done: g.done,
              ),
          ],
        ),
      ),
    );
  }

  static String _goalLabel(LevelGoal g) => switch (g.type) {
        GoalType.collect => g.piece!.name,
        GoalType.score => 'Target',
      };
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label,
      required this.value,
      this.color,
      this.done = false});
  final String label;
  final String value;
  final Color? color;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: color == null ? null : Border.all(color: color!, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: t.labelSmall),
          Text(done ? '✓' : value,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class ResultOverlay extends StatelessWidget {
  const ResultOverlay(
      {super.key, required this.game, this.onNext, required this.onLevels});
  final SushiGame game;

  /// Null when there is no next level.
  final VoidCallback? onNext;
  final VoidCallback onLevels;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HudState>(
      valueListenable: game.hud,
      builder: (context, s, _) {
        if (s.status == GameStatus.playing) return const SizedBox.shrink();
        final won = s.status == GameStatus.won;
        return ColoredBox(
          color: Colors.black38,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(won ? 'Oishii! 🍣' : 'Out of moves',
                        style: Theme.of(context).textTheme.headlineSmall),
                    if (won) ...[
                      const SizedBox(height: 8),
                      Text('★' * s.stars + '☆' * (3 - s.stars),
                          style: const TextStyle(
                              fontSize: 32, color: Color(0xFFF5B301))),
                    ],
                    const SizedBox(height: 8),
                    Text('Score ${s.score}'),
                    const SizedBox(height: 16),
                    if (won && onNext != null) ...[
                      FilledButton(
                          onPressed: onNext, child: const Text('Next level')),
                      const SizedBox(height: 8),
                    ],
                    won && onNext != null
                        ? OutlinedButton(
                            onPressed: game.restart,
                            child: const Text('Play again'))
                        : FilledButton(
                            onPressed: game.restart,
                            child: Text(won ? 'Play again' : 'Retry')),
                    const SizedBox(height: 8),
                    OutlinedButton(
                        onPressed: onLevels, child: const Text('Level select')),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
