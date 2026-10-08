import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/progress.dart';
import '../core/settings.dart';
import '../gen/assets.gen.dart';
import '../services/restaurant.dart';
import 'level_select.dart';
import 'navigation.dart';

class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testMode = ref.watch(settingsProvider.select((s) => s.testMode));
    final cleared = testMode ? kLevelCount : ref.watch(progressProvider);
    final restaurant = ref.watch(restaurantProvider);
    // Rebuild on a language change; L10n reads it statically.
    ref.watch(settingsProvider.select((s) => s.language));
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: Assets.backgrounds.bg.provider(),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LevelSelectView(
            levelCount: kLevelCount,
            cleared: cleared,
            stars: restaurant.best,
            onBack: () => Navigator.of(context).maybePop(),
            onRestaurant: () => openRestaurant(context),
            onShop: () => openShop(context),
            onSettings: () => openSettings(context),
            onSelect: (n) => startLevel(context, ref, n),
          ),
        ),
      ),
    );
  }
}
