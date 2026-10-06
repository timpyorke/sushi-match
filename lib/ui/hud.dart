import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/game_engine.dart';
import '../game/sushi_game.dart';
import '../services/wallet.dart';
import 'customer_order.dart';
import 'l10n.dart';
import 'lives_ui.dart';
import 'shop_screen.dart';
import 'ui_art.dart';

/// Moves left plus the score as a bar that fills toward the third star, with
/// each star sitting at the score that earns it.
class HudBar extends StatelessWidget {
  const HudBar({super.key, required this.game});
  final SushiGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HudState>(
      valueListenable: game.hud,
      builder: (context, s, _) => Row(
        children: [
          _Chip(label: L10n.t('moves'), value: '${s.movesLeft}'),
          const SizedBox(width: 8),
          Expanded(
              child: _ScoreStars(score: s.score, thresholds: game.level.stars)),
        ],
      ),
    );
  }
}

class _ScoreStars extends StatelessWidget {
  const _ScoreStars({required this.score, required this.thresholds});
  final int score;
  final List<int> thresholds;

  static const _star = 26.0;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final top = thresholds.isEmpty ? 1 : thresholds.last;
    final fill = (score / top).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      decoration: UiArt.plankDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${L10n.t('score')} $score',
              style: t.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: UiArt.ink)),
          const SizedBox(height: 2),
          LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth - _star;
            return SizedBox(
              height: _star,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: _star / 2,
                    right: _star / 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: fill,
                        minHeight: 10,
                        backgroundColor: Colors.black26,
                        color: const Color(0xFFFFB300),
                      ),
                    ),
                  ),
                  for (final th in thresholds)
                    Positioned(
                      left: w * (th / top),
                      child: StarIcon(size: _star, lit: score >= th),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: UiArt.plankDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: t.labelSmall?.copyWith(color: UiArt.ink)),
          Text(value,
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
    (Booster.chopsticks, 'chopsticks'),
    (Booster.freeSwap, 'freeSwap'),
    (Booster.shuffle, 'shuffle'),
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
                  for (final (b, key) in _items)
                    Expanded(
                        child: _BoosterButton(
                      booster: b,
                      label: L10n.t(key),
                      stock: wallet.count(b),
                      active: armed == b,
                      enabled: playing,
                      // Out of stock: the "+" opens the shop to buy more.
                      onTap: wallet.count(b) > 0
                          ? () => game.tapBooster(b)
                          : () => showBoosterShopSheet(context),
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
      {required this.booster,
      required this.label,
      required this.stock,
      required this.active,
      required this.enabled,
      required this.onTap});
  final Booster booster;
  final String label;
  final int stock;
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
              BoosterIcon(booster, size: 32),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: UiArt.ink, fontSize: 11)),
              Text(stock > 0 ? '×$stock' : '+',
                  style: const TextStyle(
                      color: UiArt.ink,
                      fontSize: 14,
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
              const ShopIcon(size: 32),
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
