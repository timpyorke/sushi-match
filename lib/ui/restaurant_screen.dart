import 'package:flutter/material.dart';

import '../core/settings.dart';
import '../services/restaurant.dart';
import 'l10n.dart';
import 'ui_art.dart';

/// Spend stars on new restaurants and on decorating them.
class RestaurantScreen extends StatelessWidget {
  const RestaurantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: Listenable.merge([Settings.language, Restaurant.revision]),
      builder: (context, _) => Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: RoundIconButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Text(L10n.t('restaurant'),
                    style:
                        t.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const StarIcon(size: 28),
                    const SizedBox(width: 6),
                    Text(
                        L10n.t('starsAvailable', {'n': Restaurant.available}),
                        style: t.titleMedium),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final s in Restaurant.shops) _ShopCard(shop: s),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.shop});
  final ShopDef shop;

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final open = Restaurant.shopUnlocked(shop);
    final done = Restaurant.shopComplete(shop);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: UiArt.panelDecoration(),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: UiArt.ink),
        child: Column(
          children: [
            Row(
              children: [
                Text(shop.emoji, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(L10n.t(shop.nameKey),
                          style: t.titleMedium?.copyWith(
                              color: UiArt.ink, fontWeight: FontWeight.bold)),
                      Text(L10n.t('levelsRange',
                          {'a': shop.firstLevel, 'b': shop.lastLevel})),
                    ],
                  ),
                ),
                if (open && !done) Text(L10n.t('shopOpen')),
                if (done) const Text('✓', style: TextStyle(fontSize: 24)),
              ],
            ),
            const SizedBox(height: 12),
            if (!open)
              FilledButton(
                onPressed: () async {
                  if (!await Restaurant.buyShop(shop) && context.mounted) {
                    _toast(context, L10n.t('needStars'));
                  }
                },
                child: Text(L10n.t('unlockShop', {'n': shop.unlockCost})),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final d in shop.decor) _DecorTile(shop: shop, decor: d),
                ],
              ),
              if (done) ...[
                const SizedBox(height: 12),
                Text(L10n.t('shopDoneTitle'),
                    style: t.titleSmall?.copyWith(color: UiArt.ink)),
                Text(L10n.t('shopDoneReward',
                    {'n': Restaurant.completeCoins})),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DecorTile extends StatelessWidget {
  const _DecorTile({required this.shop, required this.decor});
  final ShopDef shop;
  final DecorDef decor;

  @override
  Widget build(BuildContext context) {
    final owned = Restaurant.decorOwned(shop, decor);
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: owned
          ? null
          : () async {
              final ok = await Restaurant.buyDecor(shop, decor);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                    content: Text(L10n.t(ok ? 'decorBought' : 'needStars'))));
            },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: owned ? 1 : 0.3,
            child: Text(decor.emoji, style: const TextStyle(fontSize: 40)),
          ),
          Text(L10n.t(decor.nameKey),
              style: t.labelSmall?.copyWith(color: UiArt.ink)),
          if (!owned)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${decor.cost}',
                    style: t.labelLarge?.copyWith(
                        color: UiArt.ink, fontWeight: FontWeight.bold)),
                const StarIcon(size: 14),
              ],
            ),
        ],
      ),
    );
  }
}
