import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/game_engine.dart';
import '../game/sushi_game.dart';
import '../services/restaurant.dart';
import '../services/wallet.dart';
import 'customer_order.dart';
import 'l10n.dart';
import 'lives_ui.dart';
import 'ui_art.dart';

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
                      OutlinedTitle(L10n.t(won ? 'win' : 'lose'),
                          style: Theme.of(context).textTheme.headlineSmall),
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
                      CustomerSprite(
                        customer: Customer.forLevel(game.level.id),
                        anim: won ? CustomerAnim.happy : CustomerAnim.sad,
                        intro: won &&
                                Customer.forLevel(game.level.id)
                                        .signature
                                        ?.cue ==
                                    SignatureCue.served
                            ? CustomerAnim.signature
                            : null,
                        introLoops: 1,
                        size: 112,
                      ),
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
                      if (won)
                        Text(L10n.t('sushiEarned',
                            {'n': Restaurant.sushiReward(s.stars)})),
                      if (s.eventGain > 0)
                        Text(L10n.t('eventGain', {'n': s.eventGain})),
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
