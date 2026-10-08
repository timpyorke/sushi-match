import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import '../gen/assets.gen.dart';
import '../services/audio.dart';
import '../services/restaurant.dart';
import 'l10n.dart';
import 'lives_ui.dart';
import 'restaurant_panels.dart';
import 'restaurant_scene.dart';
import 'ui_art.dart';

/// The player's one restaurant: put sushi won in levels on the display case,
/// spend stars on furniture by category, and collect the coins customers
/// leave in the till.
class RestaurantScreen extends ConsumerStatefulWidget {
  const RestaurantScreen({super.key});

  @override
  ConsumerState<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends ConsumerState<RestaurantScreen> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    // Customers buy with the clock; book their sales every second.
    // The screen rebuilds when a sale changes the state.
    _tick = Timer.periodic(const Duration(seconds: 1),
        (_) => ref.read(restaurantProvider.notifier).settle());
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _buy(FurnitureDef f) {
    final ok = ref.read(restaurantProvider.notifier).buyFurniture(f);
    if (ok) Audio.play(Sfx.coin);
    _toast(ok
        ? L10n.t(
            'furnitureBought', {'name': L10n.t(f.nameKey), 'n': f.appeal * 2})
        : L10n.t('needStars'));
  }

  Future<void> _place(int slot) async {
    final view = ref.read(restaurantProvider.notifier).view();
    if (slot >= view.slotCount) return _toast(L10n.t('slotLocked'));
    final kind = await pickSushi(context, view);
    if (kind == null) return;
    ref.read(restaurantProvider.notifier).place(kind, slot);
  }

  void _take(int slot) => ref.read(restaurantProvider.notifier).take(slot);

  void _collect() {
    final n = ref.read(restaurantProvider.notifier).collect();
    if (n <= 0) return;
    Audio.play(Sfx.coin);
    _toast(L10n.t('tillCollected', {'n': n}));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    // Rebuild when the language changes; L10n reads it statically.
    ref.watch(settingsProvider.select((s) => s.language));
    final state = ref.watch(restaurantProvider);
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
                    sprite: const UiControlIcon(UiControl.back,
                        color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: WalletBar(),
                      ),
                    ),
                  ),
                ],
              ),
              OutlinedTitle(L10n.t('restaurant'), style: t.headlineLarge),
              const SizedBox(height: 8),
              PlankSubtitle(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const StarIcon(size: 24),
                    const SizedBox(width: 6),
                    Text(L10n.t('starsAvailable', {'n': state.available})),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    RestaurantScene(onBuy: _buy),
                    const SizedBox(height: 12),
                    ShelfPanel(state: state, onPlace: _place, onTake: _take),
                    const SizedBox(height: 12),
                    TillPanel(state: state, onCollect: _collect),
                    const SizedBox(height: 12),
                    FurniturePanel(state: state, onBuy: _buy),
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
