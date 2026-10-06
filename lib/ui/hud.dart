import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/game_engine.dart';
import '../core/level.dart';
import '../game/piece_painter.dart';
import '../game/sushi_game.dart';
import '../services/wallet.dart';
import 'customer_order.dart';
import 'l10n.dart';
import 'lives_ui.dart';
import 'shop_screen.dart';
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
            _Chip(label: L10n.t('moves'), value: '${s.movesLeft}'),
            _Chip(label: L10n.t('score'), value: '${s.score}'),
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
        GoalType.collect => L10n.t(g.piece!.name),
        GoalType.score => L10n.t('target'),
        GoalType.clearNori => L10n.t('nori'),
        GoalType.breakIce => L10n.t('ice'),
        GoalType.breakBag => L10n.t('bag'),
        GoalType.deliver => L10n.t('deliver'),
        GoalType.clearMats => L10n.t('mat'),
        GoalType.putOut => L10n.t('fire'),
        GoalType.shooCats => L10n.t('cat'),
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

class ResultOverlay extends ConsumerWidget {
  const ResultOverlay(
      {super.key, required this.game, this.onNext, required this.onLevels});
  final SushiGame game;

  /// Null when there is no next level.
  final VoidCallback? onNext;
  final VoidCallback onLevels;

  /// Replaying costs a life only when the last run was lost, but starting
  /// any run needs one in the bank.
  Future<void> _again(BuildContext context, WidgetRef ref) async {
    if (await ensureLife(context, ref)) game.restart();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
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
                      Text(L10n.t(won ? 'win' : 'lose'),
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
                      Text(
                        L10n.t(won ? 'custWin' : 'custLose', {
                          'name': Customer.forLevel(game.level.id).name,
                        }),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(L10n.t('scoreN', {'n': s.score})),
                      if (won && s.reward > 0)
                        Text(L10n.t('reward', {'n': s.reward})),
                      const SizedBox(height: 16),
                      if (!won) ...[
                        FilledButton(
                          onPressed: wallet.canUse(Booster.extraMoves)
                              ? game.buyExtraMoves
                              : null,
                          child: Text(L10n.t('extraMoves', {
                            'm': Wallet.extraMovesAmount,
                            'n': wallet.count(Booster.extraMoves) > 0
                                ? 0
                                : Wallet.cost[Booster.extraMoves]!,
                          })),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (won && onNext != null) ...[
                        FilledButton(
                            onPressed: onNext,
                            child: Text(L10n.t('nextLevel'))),
                        const SizedBox(height: 8),
                      ],
                      won && onNext != null
                          ? OutlinedButton(
                              onPressed: () => _again(context, ref),
                              child: Text(L10n.t('playAgain')))
                          : FilledButton(
                              onPressed: () => _again(context, ref),
                              child: Text(L10n.t(won ? 'playAgain' : 'retry'))),
                      const SizedBox(height: 8),
                      OutlinedButton(
                          onPressed: onLevels,
                          child: Text(L10n.t('levelSelect'))),
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

/// Booster buttons under the board. Shows stock, or the coin price when the
/// stock is empty, plus a one-line hint while a booster is armed.
class BoosterBar extends ConsumerWidget {
  const BoosterBar({super.key, required this.game});
  final SushiGame game;

  static const _items = [
    (Booster.chopsticks, '🥢', 'chopsticks'),
    (Booster.freeSwap, '🔄', 'freeSwap'),
    (Booster.shuffle, '🔀', 'shuffle'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    return ListenableBuilder(
      listenable: Listenable.merge([game.armed, game.hud]),
      builder: (context, _) {
        final armed = game.armed.value;
        final playing = game.hud.value.status == GameStatus.playing;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (armed != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    L10n.t(armed == Booster.chopsticks
                        ? 'hintChopsticks'
                        : 'hintFreeSwap'),
                    style: const TextStyle(
                        color: UiArt.ink, fontWeight: FontWeight.bold),
                  ),
                ),
              Row(
                children: [
                  for (final (b, icon, key) in _items)
                    Expanded(
                        child: _BoosterButton(
                      icon: icon,
                      label: L10n.t(key),
                      stock: wallet.count(b),
                      price: Wallet.cost[b]!,
                      active: armed == b,
                      enabled: playing && wallet.canUse(b),
                      onTap: () => game.tapBooster(b),
                    )),
                  _ShopButton(
                      enabled: playing,
                      onTap: () => showBoosterShopSheet(context)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BoosterButton extends StatelessWidget {
  const _BoosterButton(
      {required this.icon,
      required this.label,
      required this.stock,
      required this.price,
      required this.active,
      required this.enabled,
      required this.onTap});
  final String icon;
  final String label;
  final int stock;
  final int price;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: UiArt.plankDecoration().copyWith(
            boxShadow: active
                ? const [BoxShadow(color: Color(0xCCFFD54F), blurRadius: 12)]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: UiArt.ink, fontSize: 11)),
              if (stock > 0)
                Text('×$stock',
                    style: const TextStyle(
                        color: UiArt.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.bold))
              else
                CoinAmount(price,
                    size: 14,
                    style: const TextStyle(
                        color: UiArt.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the booster shop sheet without leaving the level.
class _ShopButton extends StatelessWidget {
  const _ShopButton({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 52,
          margin: const EdgeInsets.only(left: 3),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: UiArt.plankDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🛒', style: TextStyle(fontSize: 22)),
              Text(L10n.t('shop'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: UiArt.ink, fontSize: 11)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
