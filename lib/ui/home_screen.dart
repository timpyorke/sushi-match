import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/progress.dart';
import '../core/settings.dart';
import '../services/audio.dart';
import '../services/restaurant.dart';
import 'daily_reward_dialog.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) maybeShowDailyReward(context, ref);
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
    final cleared =
        testMode ? widget.levelCount : ref.watch(progressProvider);
    final maxPlayable = testMode
        ? widget.levelCount
        : ref.watch(restaurantProvider).maxPlayableLevel;
    // Rebuild on a language change; L10n reads it statically.
    ref.watch(settingsProvider.select((s) => s.language));
    // Past the last level (or the last unlocked restaurant) replay the latest.
    final next = (cleared + 1)
        .clamp(1, math.min(widget.levelCount, maxPlayable))
        .toInt();
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
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 12, top: 8),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: WalletBar(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: RoundIconButton(
                        icon: Icons.settings, onPressed: widget.onSettings),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
                                icon: Icons.grid_view_rounded,
                                label: L10n.t('chooseLevel'),
                                onTap: widget.onLevels),
                            _ShortcutButton(
                                icon: Icons.storefront,
                                label: L10n.t('restaurant'),
                                onTap: widget.onRestaurant),
                            _ShortcutButton(
                                icon: Icons.shopping_bag,
                                label: L10n.t('shop'),
                                onTap: widget.onShop),
                          ],
                        ),
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
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
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
                Icon(icon, color: UiArt.ink, size: 28),
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
