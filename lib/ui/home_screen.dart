import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gen/assets.gen.dart';
import '../core/progress.dart';
import '../core/settings.dart';
import '../services/audio.dart';
import '../services/wallet.dart';
import 'daily_reward_dialog.dart';
import 'event_banner.dart';
import 'event_dialog.dart';
import 'l10n.dart';
import 'lives_ui.dart';
import 'sushi_trio.dart';
import 'ui_art.dart';

/// The first page: logo, a big Play button for the next level, and shortcuts.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen(
      {super.key,
      required this.levelCount,
      required this.onPlay,
      required this.onLevels,
      required this.onRestaurant,
      required this.onShop,
      required this.onSettings});

  final int levelCount;

  /// Called with the level the Play button starts.
  final ValueChanged<int> onPlay;
  final VoidCallback onLevels, onRestaurant, onShop, onSettings;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400))
    ..repeat();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await maybeShowDailyReward(context, ref);
      if (mounted) await maybeShowEventStart(context, ref);
    });
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final testMode = ref.watch(settingsProvider.select((s) => s.testMode));
    final cleared = testMode ? widget.levelCount : ref.watch(progressProvider);
    // Rebuild on a language change; L10n reads it statically.
    ref.watch(settingsProvider.select((s) => s.language));
    // Past the last level replay the latest.
    final next = (cleared + 1).clamp(1, widget.levelCount).toInt();
    final t = Theme.of(context).textTheme;
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
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 12, top: 8),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: WalletBar(coinShop: true),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: RoundIconButton(
                        sprite: const UiControlIcon(UiControl.settings,
                            color: Colors.white),
                        onPressed: widget.onSettings),
                  ),
                ],
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SushiTrio(animation: _bob),
                        const SizedBox(height: 12),
                        OutlinedTitle('Sushi Trio',
                            style: t.displayMedium, strokeWidth: 8),
                        const SizedBox(height: 8),
                        PlankSubtitle(text: L10n.t('tagline')),
                        const SizedBox(height: 36),
                        _PlayButton(
                          level: next,
                          onTap: () {
                            Audio.play(Sfx.tap);
                            widget.onPlay(next);
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ShortcutButton(
                                sprite: const LevelIcon(size: 28),
                                label: L10n.t('chooseLevel'),
                                onTap: widget.onLevels),
                            _ShortcutButton(
                                sprite: const MyRestaurantIcon(size: 28),
                                label: L10n.t('restaurant'),
                                onTap: widget.onRestaurant),
                            _ShortcutButton(
                                sprite: const ShopIcon(size: 28),
                                label: L10n.t('shop'),
                                onTap: widget.onShop),
                          ],
                        ),
                        const _OwnedBoosters(),
                        const EventBanner(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every booster and power-up with how many are in stock. Ones the player
/// has none of show faded, without a count.
class _OwnedBoosters extends ConsumerWidget {
  const _OwnedBoosters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stock = ref.watch(walletProvider.select((w) => w.stock));
    final t = Theme.of(context).textTheme;
    const perRow = 3;
    const all = Booster.values;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      // A 3 x 2 grid of same-size chips.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < all.length; i += perRow)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var j = i; j < i + perRow && j < all.length; j++)
                    Padding(
                      padding: EdgeInsets.only(left: j == i ? 0 : 8),
                      child: SizedBox(
                        width: _BoosterChip.width,
                        child: _BoosterChip(
                            booster: all[j],
                            count: stock[all[j]] ?? 0,
                            style: t.labelLarge),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BoosterChip extends StatelessWidget {
  const _BoosterChip(
      {required this.booster, required this.count, required this.style});
  final Booster booster;
  final int count;
  final TextStyle? style;

  static const width = 84.0;

  @override
  Widget build(BuildContext context) {
    final owned = count > 0;
    return Opacity(
      opacity: owned ? 1 : 0.45,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: UiArt.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: UiArt.ink, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BoosterIcon(booster, size: 28),
            if (owned) ...[
              const SizedBox(width: 4),
              Text('×$count',
                  style: style?.copyWith(
                      color: UiArt.ink, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.level, required this.onTap});
  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE53950), Color(0xFFB71C2C)]),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(
                color: Colors.black38, blurRadius: 8, offset: Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(L10n.t('play'),
                style: t.headlineLarge?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            Text(L10n.t('levelN', {'n': level}),
                style: t.titleSmall?.copyWith(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  const _ShortcutButton(
      {this.icon, this.sprite, required this.label, required this.onTap})
      : assert(icon != null || sprite != null);
  final IconData? icon;
  final Widget? sprite;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: GestureDetector(
          onTap: () {
            Audio.play(Sfx.tap);
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: UiArt.paper,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: UiArt.ink, width: 2),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                sprite ?? Icon(icon, color: UiArt.ink, size: 28),
                const SizedBox(height: 2),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelMedium?.copyWith(
                        color: UiArt.ink, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
