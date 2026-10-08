import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gen/assets.gen.dart';
import '../services/audio.dart';
import '../services/iap.dart';
import 'l10n.dart';
import 'shop_screen.dart';
import 'ui_art.dart';

/// Buy coins with real money. Purchases go through [iapProvider]; until a
/// store is wired up the buttons report "coming soon".
class CoinShopScreen extends ConsumerWidget {
  const CoinShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final iap = ref.watch(iapProvider);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: Assets.backgrounds.bg.provider(),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  const CoinPill(tappable: false),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child:
                    OutlinedTitle(L10n.t('getCoins'), style: t.headlineLarge),
              ),
              if (!iap.available)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(L10n.t('iapSoon'),
                      style: t.bodyMedium?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    for (final pack in coinPacks) _PackCard(pack: pack),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackCard extends ConsumerWidget {
  const _PackCard({required this.pack});
  final CoinPack pack;

  Future<void> _buy(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await buyCoinPack(ref, pack);
    if (result == IapResult.success) Audio.play(Sfx.coin);
    final key = switch (result) {
      IapResult.success => 'bought',
      IapResult.cancelled => null,
      IapResult.unavailable => 'iapSoon',
      IapResult.failed => 'iapFailed',
    };
    if (key == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          duration: const Duration(seconds: 2), content: Text(L10n.t(key))));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final iap = ref.watch(iapProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      // Keep content clear of the panel frame's wave corners.
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
      decoration: UiArt.panelDecoration(),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: UiArt.ink),
        child: Row(
          children: [
            UiArt.sized(UiArt.coin, 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L10n.t('coinsAmount', {'n': pack.coins}),
                      style:
                          t.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  if (pack.bonus > 0)
                    Text(L10n.t('coinsBonus', {'n': pack.bonus}),
                        style: t.bodySmall?.copyWith(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _buy(context, ref),
              style: FilledButton.styleFrom(
                minimumSize: const Size(88, 36),
                backgroundColor: iap.available ? null : Colors.grey,
              ),
              child: Text(iap.priceOf(pack) ?? pack.fallbackPrice),
            ),
          ],
        ),
      ),
    );
  }
}
