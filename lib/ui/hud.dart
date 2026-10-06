import 'package:flutter/material.dart';

import '../core/game_engine.dart';
import '../core/level.dart';
import '../game/piece_painter.dart';
import '../game/sushi_game.dart';
import 'ui_art.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: UiArt.plankDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: UiArt.ink, width: 1.5),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(label, style: t.labelSmall?.copyWith(color: UiArt.ink)),
            ],
          ),
          Text(done ? '✓' : value,
              style: t.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: UiArt.ink)),
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
            child: Container(
              width: 320,
              decoration: UiArt.panelDecoration(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 44, vertical: 48),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: UiArt.ink),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(won ? 'Oishii! 🍣' : 'Out of moves',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: UiArt.ink)),
                      if (won) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < 3; i++)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: StarIcon(size: 40, lit: i < s.stars),
                              ),
                          ],
                        ),
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
                          onPressed: onLevels,
                          child: const Text('Level select')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Chef's cheer that pops in over the board after a combo and fades out.
class PraiseBanner extends StatelessWidget {
  const PraiseBanner({super.key, required this.game});
  final SushiGame game;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<({String text, int n})?>(
        valueListenable: game.praise,
        builder: (context, p, _) {
          if (p == null) return const SizedBox.shrink();
          return Center(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(p.n),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1100),
              builder: (context, t, child) => Opacity(
                opacity: t < 0.7 ? 1 : (1 - t) / 0.3,
                child: Transform.scale(
                  scale: 0.6 +
                      0.6 * Curves.easeOutBack.transform((t * 3).clamp(0, 1)),
                  child: child,
                ),
              ),
              child: Text(
                p.text,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: const [
                    Shadow(color: UiArt.ink, blurRadius: 6),
                    Shadow(color: UiArt.ink, offset: Offset(2, 2)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
