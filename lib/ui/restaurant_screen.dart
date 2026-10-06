import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import '../services/audio.dart';
import '../services/restaurant.dart';
import 'l10n.dart';
import 'ui_art.dart';

/// Spend stars on new restaurants and on decorating them.
class RestaurantScreen extends ConsumerWidget {
  const RestaurantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    // Rebuild when the language changes; L10n reads it statically.
    ref.watch(settingsProvider.select((s) => s.language));
    final shops = ref.watch(restaurantProvider);
    return Builder(
      builder: (context) => Scaffold(
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: RoundIconButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                OutlinedTitle(L10n.t('restaurant'), style: t.headlineLarge),
                const SizedBox(height: 8),
                PlankSubtitle(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const StarIcon(size: 24),
                      const SizedBox(width: 6),
                      Text(L10n.t('starsAvailable', {'n': shops.available})),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
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

class _ShopCard extends ConsumerWidget {
  const _ShopCard({required this.shop});
  final ShopDef shop;

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final state = ref.watch(restaurantProvider);
    final open = state.shopUnlocked(shop);
    final done = state.shopComplete(shop);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      // Same inset as GameDialog so content clears the wave-corner frame.
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
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
                onPressed: () {
                  if (!ref.read(restaurantProvider.notifier).buyShop(shop)) {
                    _toast(context, L10n.t('needStars'));
                  }
                },
                child: Text(L10n.t('unlockShop', {'n': shop.unlockCost})),
              )
            else ...[
              ShopScene(shop: shop),
              if (done) ...[
                const SizedBox(height: 12),
                Text(L10n.t('shopDoneTitle'),
                    style: t.titleSmall?.copyWith(color: UiArt.ink)),
                Text(L10n.t('shopDoneReward', {'n': Restaurant.completeCoins})),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Where each decoration sits in the scene, as fractions of its size.
const _slots = {
  'lantern': Alignment(-0.62, 0.12),
  'sign': Alignment(0, -0.7),
  'table': Alignment(0.62, 0.72),
};

class _Palette {
  const _Palette(this.sky, this.wall, this.awningA, this.awningB, this.floor);
  final Color sky;
  final Color wall;
  final Color awningA;
  final Color awningB;
  final Color floor;
}

const _palettes = {
  'tsukiji': _Palette(Color(0xFFBFE3F0), Color(0xFFE9D3A8), Color(0xFF2F5D8C),
      Color(0xFFF4EBD8), Color(0xFFB98A5A)),
  'osaka': _Palette(Color(0xFFF6C9A0), Color(0xFFE8C48F), Color(0xFFC0392B),
      Color(0xFFFFF1D6), Color(0xFF9C6B43)),
  'kyoto': _Palette(Color(0xFFD9CFEA), Color(0xFFD8C7A3), Color(0xFF5E7F4F),
      Color(0xFFF3EBD3), Color(0xFF8A6B4A)),
  'hokkaido': _Palette(Color(0xFFD4ECF7), Color(0xFFCBD9E2), Color(0xFF1F6F8B),
      Color(0xFFF7FBFD), Color(0xFF8B8F96)),
  'fukuoka': _Palette(Color(0xFF2E3A66), Color(0xFFD9B47C), Color(0xFFB8322A),
      Color(0xFFFFE9B8), Color(0xFF6E4B34)),
  'okinawa': _Palette(Color(0xFF9FE0E8), Color(0xFFF1DDB0), Color(0xFF1AA6A6),
      Color(0xFFFFF6DF), Color(0xFFD9B98A)),
  'omakase': _Palette(Color(0xFF3A2A3F), Color(0xFFC9A66B), Color(0xFF8E1B2D),
      Color(0xFFF6E3B0), Color(0xFF3B2A22)),
};

/// A little street stall that fills up as decorations are bought. Empty
/// spots show a faint price tag; tapping one buys it.
class ShopScene extends ConsumerWidget {
  const ShopScene({super.key, required this.shop});
  final ShopDef shop;

  void _buy(BuildContext context, WidgetRef ref, DecorDef d) {
    final ok = ref.read(restaurantProvider.notifier).buyDecor(shop, d);
    if (ok) Audio.play(Sfx.coin);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(content: Text(L10n.t(ok ? 'decorBought' : 'needStars'))));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owned = ref.watch(restaurantProvider);
    final palette = _palettes[shop.id] ?? _palettes['tsukiji']!;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _ScenePainter(palette)),
            for (final d in shop.decor)
              Align(
                alignment: _slots[d.id] ?? Alignment.center,
                child: _Slot(
                  decor: d,
                  owned: owned.decorOwned(shop, d),
                  onBuy: () => _buy(context, ref, d),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.decor, required this.owned, required this.onBuy});
  final DecorDef decor;
  final bool owned;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: owned ? null : onBuy,
      child: SizedBox(
        width: 76,
        height: 76,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: owned ? 0 : 1,
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: Colors.white70,
                  shape: BoxShape.circle,
                  border: Border.all(color: UiArt.ink.withAlpha(150), width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: 0.55,
                      child: Text(decor.emoji,
                          style: const TextStyle(fontSize: 26)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${decor.cost}',
                            style: t.labelLarge?.copyWith(
                                color: UiArt.ink, fontWeight: FontWeight.bold)),
                        const StarIcon(size: 13),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            AnimatedScale(
              scale: owned ? 1 : 0,
              duration: const Duration(milliseconds: 450),
              curve: Curves.elasticOut,
              child: Text(decor.emoji, style: const TextStyle(fontSize: 52)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.p);
  final _Palette p;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = p.sky);
    // Back wall of the stall.
    canvas.drawRect(Rect.fromLTWH(w * 0.06, h * 0.3, w * 0.88, h * 0.5),
        Paint()..color = p.wall);
    // Striped awning.
    const stripes = 10;
    final sw = w * 0.92 / stripes;
    for (var i = 0; i < stripes; i++) {
      final path = Path()
        ..moveTo(w * 0.04 + i * sw, h * 0.3)
        ..lineTo(w * 0.04 + (i + 1) * sw, h * 0.3)
        ..lineTo(w * 0.04 + (i + 1) * sw, h * 0.44)
        ..arcToPoint(Offset(w * 0.04 + i * sw, h * 0.44),
            radius: Radius.circular(sw / 2), clockwise: true)
        ..close();
      canvas.drawPath(path, Paint()..color = i.isEven ? p.awningA : p.awningB);
    }
    // Counter and floor.
    canvas.drawRect(Rect.fromLTWH(w * 0.06, h * 0.66, w * 0.88, h * 0.14),
        Paint()..color = p.floor.withAlpha(235));
    canvas.drawRect(
        Rect.fromLTWH(0, h * 0.8, w, h * 0.2), Paint()..color = p.floor);
    final plank = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 2;
    for (var i = 1; i < 4; i++) {
      final y = h * 0.8 + i * h * 0.05;
      canvas.drawLine(Offset(0, y), Offset(w, y), plank);
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.p != p;
}
