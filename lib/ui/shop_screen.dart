import 'package:flutter/material.dart';

import '../services/wallet.dart';
import 'l10n.dart';
import 'ui_art.dart';

/// Where coins turn into boosters (and lives). Stock bought here is used
/// before any coins are charged in a level.
class BoosterShopScreen extends StatelessWidget {
  const BoosterShopScreen({super.key});

  static const _items = [
    (Booster.extraMoves, '➕', 'extraMovesName', 'descExtraMoves'),
    (Booster.chopsticks, '🥢', 'chopsticks', 'descChopsticks'),
    (Booster.freeSwap, '🔄', 'freeSwap', 'descFreeSwap'),
    (Booster.shuffle, '🔀', 'shuffle', 'descShuffle'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable:
                Listenable.merge([Wallet.coins, Wallet.stock, Wallet.lives]),
            builder: (context, _) => Column(
              children: [
                Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.only(right: 12, top: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: UiArt.plankDecoration(),
                      child: CoinAmount(Wallet.coins.value,
                          size: 20,
                          style: const TextStyle(
                              color: UiArt.ink, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(L10n.t('shop'),
                      style: t.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      for (final (b, emoji, name, desc) in _items)
                        _BoosterCard(
                            booster: b,
                            emoji: emoji,
                            name: L10n.t(name),
                            desc: L10n.t(desc)),
                      const _LivesCard(),
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

void _toast(BuildContext context, String key) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 1), content: Text(L10n.t(key))));
}

class _Card extends StatelessWidget {
  const _Card({required this.leading, required this.body, required this.buy});
  final Widget leading;
  final Widget body;
  final Widget buy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: UiArt.panelDecoration(),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: UiArt.ink),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(child: body),
            const SizedBox(width: 8),
            buy,
          ],
        ),
      ),
    );
  }
}

class _BoosterCard extends StatelessWidget {
  const _BoosterCard(
      {required this.booster,
      required this.emoji,
      required this.name,
      required this.desc});
  final Booster booster;
  final String emoji;
  final String name;
  final String desc;

  Widget _buyButton(BuildContext context, int qty) {
    final price = Wallet.price(booster, qty);
    final affordable = Wallet.coins.value >= price;
    return FilledButton(
      onPressed: () {
        final ok = Wallet.buy(booster, qty);
        _toast(context, ok ? 'bought' : 'notEnoughCoins');
      },
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(88, 36),
        backgroundColor: affordable ? null : Colors.grey,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('×$qty  '),
          CoinAmount(price,
              size: 16, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return _Card(
      leading: Text(emoji, style: const TextStyle(fontSize: 34)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(desc, style: t.bodySmall),
          const SizedBox(height: 2),
          Text(L10n.t('owned', {'n': Wallet.count(booster)}),
              style: t.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
      buy: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buyButton(context, 1),
          const SizedBox(height: 6),
          _buyButton(context, Wallet.bundleSize),
          Text(L10n.t('bundleSave'),
              style: t.labelSmall?.copyWith(color: Colors.green.shade800)),
        ],
      ),
    );
  }
}

class _LivesCard extends StatelessWidget {
  const _LivesCard();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final full = Wallet.lives.value >= Wallet.maxLives;
    return _Card(
      leading: const Text('❤️', style: TextStyle(fontSize: 34)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.t('livesTitle'),
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(
              full
                  ? L10n.t('livesFull')
                  : '${Wallet.lives.value} / ${Wallet.maxLives}',
              style: t.bodySmall),
        ],
      ),
      buy: FilledButton(
        onPressed: full
            ? null
            : () => _toast(context,
                Wallet.refillLifeWithCoins() ? 'bought' : 'notEnoughCoins'),
        child: Text(L10n.t('refill', {'n': Wallet.lifeRefillCost})),
      ),
    );
  }
}
