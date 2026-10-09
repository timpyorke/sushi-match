import 'package:flutter/material.dart';

import '../services/audio.dart';
import '../services/restaurant.dart';
import 'l10n.dart';
import 'lives_ui.dart';
import 'map/japan_map.dart';
import 'map/tile_map.dart';
import 'ui_art.dart';

/// Level picker drawn as a tile map of Japan. Each restaurant is one band of
/// the map with its levels along a route. Opens scrolled to the next level.
class LevelSelectView extends StatefulWidget {
  const LevelSelectView(
      {super.key,
      required this.levelCount,
      required this.cleared,
      this.stars = const {},
      required this.onSelect,
      this.onRestaurant,
      this.onShop,
      this.onSettings,
      this.onBack});

  final int levelCount;

  /// Shows a back button at the top left when set.
  final VoidCallback? onBack;

  /// Highest cleared level; the next one is playable, the rest are locked.
  final int cleared;

  /// Best stars (1-3) per level number.
  final Map<int, int> stars;
  final ValueChanged<int> onSelect;
  final VoidCallback? onRestaurant;
  final VoidCallback? onShop;
  final VoidCallback? onSettings;

  @override
  State<LevelSelectView> createState() => _LevelSelectViewState();
}

class _LevelSelectViewState extends State<LevelSelectView> {
  late final _layout = MapLayout(Restaurant.shops, widget.levelCount);

  void _tap(int n) {
    if (n > widget.cleared + 1) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text(L10n.t('clearFirst', {'n': n - 1}))));
      return;
    }
    Audio.play(Sfx.tap);
    widget.onSelect(n);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Row(
          children: [
            if (widget.onBack != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: RoundIconButton(
                    sprite: const UiControlIcon(UiControl.back,
                        color: Colors.white),
                    onPressed: widget.onBack!),
              ),
            // Shrinks on narrow phones so the three buttons still fit.
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
            if (widget.onSettings != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: RoundIconButton(
                    sprite: const UiControlIcon(UiControl.settings,
                        color: Colors.white),
                    onPressed: widget.onSettings!),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 14),
          child: OutlinedTitle('Sushi Trio', style: t.headlineLarge),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: TileMapView(
                  layout: _layout,
                  cleared: widget.cleared,
                  stars: widget.stars,
                  // A region stays dimmed until the player reaches its first level.
                  lockedShop: (s) =>
                      _layout.shops[s].firstLevel > widget.cleared + 1,
                  onTap: _tap,
                ),
              ),
              // Shop and restaurant stacked down the right edge.
              if (widget.onShop != null || widget.onRestaurant != null)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onShop != null)
                        RoundIconButton(
                            sprite: const ShopIcon(size: 28),
                            onPressed: widget.onShop!),
                      if (widget.onShop != null && widget.onRestaurant != null)
                        const SizedBox(height: 10),
                      if (widget.onRestaurant != null)
                        RoundIconButton(
                            icon: Icons.storefront,
                            onPressed: widget.onRestaurant!),
                    ],
                  ),
                ),
              // Floats over the sea at the bottom; touches pass through.
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: IgnorePointer(
                  child:
                      Center(child: PlankSubtitle(text: L10n.t('pickPlate'))),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
