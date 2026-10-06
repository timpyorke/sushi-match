import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio.dart';
import '../services/wallet.dart';
import 'l10n.dart';
import 'ui_art.dart';

/// Where coins turn into boosters (and lives). Stock bought here is used
/// before any coins are charged in a level.
class BoosterShopScreen extends StatelessWidget {
  const BoosterShopScreen({super.key});

  static const _items = [
    (Booster.extraMoves, 'extraMovesName', 'descExtraMoves'),
    (Booster.chopsticks, 'chopsticks', 'descChopsticks'),
    (Booster.freeSwap, 'freeSwap', 'descFreeSwap'),
    (Booster.shuffle, 'shuffle', 'descShuffle'),
    (Booster.starterKnife, 'starterKnife', 'descStarterKnife'),
    (Booster.starterWasabi, 'starterWasabi', 'descStarterWasabi'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backgrounds/bg.png'),
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
                  const _CoinPill(),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(L10n.t('shop'),
                    style:
                        t.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const Expanded(child: BoosterShopList()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coin balance on a plank.
class _CoinPill extends ConsumerWidget {
  const _CoinPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(walletProvider.select((w) => w.coins));
    return Container(
      margin: const EdgeInsets.only(right: 12, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: UiArt.plankDecoration(),
      child: CoinAmount(coins,
          size: 20,
          style:
              const TextStyle(color: UiArt.ink, fontWeight: FontWeight.bold)),
    );
  }
}

/// The scrolling list of things to buy; shared by the shop screen and the
/// in-level sheet.
class BoosterShopList extends StatelessWidget {
  const BoosterShopList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        for (final (b, name, desc) in BoosterShopScreen._items)
          _BoosterCard(booster: b, name: L10n.t(name), desc: L10n.t(desc)),
        const _LivesCard(),
      ],
    );
  }
}

/// Opens the shop over the current level so boosters can be topped up
/// without leaving the board.
Future<void> showBoosterShopSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF3E3C3),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    // Own messenger + scaffold so purchase toasts show above the sheet rather
    // than behind it on the level's scaffold.
    builder: (context) => SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: ScaffoldMessenger(
          child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
              child: Row(
                children: [
                  const ShopIcon(size: 32),
                  const SizedBox(width: 8),
                  Text(L10n.t('shop'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: UiArt.ink, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Padding(
                      padding: EdgeInsets.only(bottom: 8), child: _CoinPill()),
                  IconButton(
                      icon: const Icon(Icons.close, color: UiArt.ink),
                      onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            const Expanded(child: BoosterShopList()),
          ],
        ),
      )),
    ),
  );
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

class _BoosterCard extends ConsumerWidget {
  const _BoosterCard(
      {required this.booster, required this.name, required this.desc});
  final Booster booster;
  final String name;
  final String desc;

  Widget _buyButton(BuildContext context, WidgetRef ref, int qty) {
    final price = Wallet.price(booster, qty);
    final affordable = ref.watch(walletProvider).coins >= price;
    return FilledButton(
      onPressed: () {
        final ok = ref.read(walletProvider.notifier).buy(booster, qty);
        if (ok) Audio.play(Sfx.coin);
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
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    return _Card(
      leading: BoosterIcon(booster, size: 48),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(desc, style: t.bodySmall),
          const SizedBox(height: 2),
          Text(L10n.t('owned', {'n': ref.watch(walletProvider).count(booster)}),
              style: t.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
      buy: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buyButton(context, ref, 1),
          const SizedBox(height: 6),
          _buyButton(context, ref, Wallet.bundleSize),
          Text(L10n.t('bundleSave'),
              style: t.labelSmall?.copyWith(color: Colors.green.shade800)),
        ],
      ),
    );
  }
}

class _LivesCard extends ConsumerWidget {
  const _LivesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final lives = ref.watch(walletProvider.select((w) => w.lives));
    final full = lives >= Wallet.maxLives;
    return _Card(
      leading: const Text('❤️', style: TextStyle(fontSize: 34)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.t('livesTitle'),
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(full ? L10n.t('livesFull') : '$lives / ${Wallet.maxLives}',
              style: t.bodySmall),
        ],
      ),
      buy: FilledButton(
        onPressed: full
            ? null
            : () {
                final ok =
                    ref.read(walletProvider.notifier).refillLifeWithCoins();
                if (ok) Audio.play(Sfx.coin);
                _toast(context, ok ? 'bought' : 'notEnoughCoins');
              },
        child: Text(L10n.t('refill', {'n': Wallet.lifeRefillCost})),
      ),
    );
  }
}
