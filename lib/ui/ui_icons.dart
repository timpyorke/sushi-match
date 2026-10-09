import 'package:flutter/material.dart';

import '../gen/assets.gen.dart';
import '../services/wallet.dart';
import 'ui_art.dart';

/// Booster sprite (the starter boosters use the power sprites).
class BoosterIcon extends StatelessWidget {
  const BoosterIcon(this.booster, {super.key, this.size = 32});
  final Booster booster;
  final double size;

  static final _sprites = {
    Booster.extraMoves: Assets.sprites.boosters.hourglass,
    Booster.chopsticks: Assets.sprites.boosters.chopsticks,
    Booster.freeSwap: Assets.sprites.boosters.swap,
    Booster.shuffle: Assets.sprites.boosters.shuffle,
    Booster.starterKnife: Assets.sprites.power.knife,
    Booster.starterWasabi: Assets.sprites.power.wasabi,
  };

  @override
  Widget build(BuildContext context) {
    final sprite = _sprites[booster];
    if (sprite == null) return SizedBox(width: size, height: size);
    return sprite.image(
        width: size,
        height: size,
        // Sprites are 192-256px; decode near display size.
        cacheWidth: (size * 3).round());
  }
}

/// Shopping cart sprite.
class ShopIcon extends StatelessWidget {
  const ShopIcon({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) => Assets.ui.shopping
      .image(width: size, height: size, cacheWidth: (size * 3).round());
}

/// The level map (scroll with a route).
class LevelIcon extends StatelessWidget {
  const LevelIcon({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) => Assets.ui.level
      .image(width: size, height: size, cacheWidth: (size * 3).round());
}

/// The player's own restaurant.
class MyRestaurantIcon extends StatelessWidget {
  const MyRestaurantIcon({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) => Assets.ui.myRestaurant
      .image(width: size, height: size, cacheWidth: (size * 3).round());
}

/// Controls that are still Material icons until their art lands in
/// `assets/ui/` (prompts in `docs/prompts/icons/ui.md`).
enum UiControl {
  back(Icons.arrow_back_ios_new),
  settings(Icons.settings),
  close(Icons.close),
  plus(Icons.add_circle),
  soundOn(Icons.volume_up),
  soundOff(Icons.volume_off),
  lock(Icons.lock_outline),
  chevron(Icons.chevron_right);

  const UiControl(this.fallback);
  final IconData fallback;
}

/// Art for each [UiControl]. Add an entry (e.g.
/// `UiControl.back: Assets.ui.back`) once the file exists and the generated
/// assets are rebuilt; the icon is then used everywhere automatically.
const _controlArt = <UiControl, AssetGenImage>{};

/// A [UiControl] drawn from its sprite, or the Material icon if it has none.
class UiControlIcon extends StatelessWidget {
  const UiControlIcon(this.control, {super.key, this.size = 24, this.color});
  final UiControl control;
  final double size;

  /// Tints the Material fallback only; the sprite keeps its own colours.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final art = _controlArt[control];
    if (art == null) return Icon(control.fallback, size: size, color: color);
    return UiArt.sized(art.provider(), size);
  }
}

/// Gold star, greyed out when [lit] is false.
class StarIcon extends StatelessWidget {
  const StarIcon({super.key, this.size = 20, this.lit = true});
  final double size;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final img = UiArt.sized(UiArt.star, size);
    if (lit) return img;
    return Opacity(
      opacity: 0.35,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.33, 0.33, 0.33, 0, 0, //
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: img,
      ),
    );
  }
}
