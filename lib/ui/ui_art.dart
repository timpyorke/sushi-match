import 'package:flutter/material.dart';

import '../gen/assets.gen.dart';
import '../services/audio.dart';
import '../services/wallet.dart';

/// Cute sticker-style title: ink fill with a thick white outline.
class OutlinedTitle extends StatelessWidget {
  const OutlinedTitle(this.text, {super.key, this.style, this.strokeWidth = 6});

  final String text;
  final TextStyle? style;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final base = (style ?? const TextStyle())
        .copyWith(fontWeight: FontWeight.bold, height: 1.2);
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(text,
            textAlign: TextAlign.center,
            style: base.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = strokeWidth
                  ..strokeJoin = StrokeJoin.round
                  ..color = Colors.white)),
        Text(text,
            textAlign: TextAlign.center,
            style: base.copyWith(color: UiArt.ink)),
      ],
    );
  }
}

/// Subtitle on the wooden plank sprite. The plank is stretched as a nine-patch
/// so the rounded ends stay undistorted.
class PlankSubtitle extends StatelessWidget {
  const PlankSubtitle({super.key, this.text, this.child})
      : assert(text != null || child != null);

  final String? text;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 6),
      decoration: UiArt.plankSpriteDecoration(),
      child: DefaultTextStyle.merge(
        style: (t.titleMedium ?? const TextStyle())
            .copyWith(color: UiArt.ink, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        child: child ?? Text(text!),
      ),
    );
  }
}

/// Sprites under assets/ui/.
abstract final class UiArt {
  static final panel = Assets.ui.panel.provider();
  static final heart = Assets.ui.heart.provider();
  static final buttonRound = Assets.ui.buttonRound.provider();
  static final star = Assets.ui.star.provider();
  static final coin = Assets.ui.coin.provider();
  static final gift = Assets.ui.gift.provider();
  static final heartBroken = Assets.ui.heartBroken.provider();
  static final check = Assets.ui.check.provider();

  /// Obstacle icon by id; the ids are the ones the game data uses.
  static AssetGenImage obstacle(String id) => switch (id) {
        'bag' => Assets.ui.obstacles.bag,
        'bomb' => Assets.ui.obstacles.bomb,
        'cat' => Assets.ui.obstacles.cat,
        'conveyor' => Assets.ui.obstacles.conveyor,
        'deliver' => Assets.ui.obstacles.deliver,
        'fire' => Assets.ui.obstacles.fire,
        'gravity' => Assets.ui.obstacles.gravity,
        'ice' => Assets.ui.obstacles.ice,
        'key' => Assets.ui.obstacles.key,
        'mat' => Assets.ui.obstacles.mat,
        'nori' => Assets.ui.obstacles.nori,
        'portal' => Assets.ui.obstacles.portal,
        _ => throw ArgumentError.value(id, 'id', 'no obstacle icon'),
      };

  /// Backdrop of a restaurant's levels; the shared one for an unknown id.
  static AssetGenImage levelBackground(String? id) => switch (id) {
        'tsukiji' => Assets.backgrounds.levelTsukiji,
        'osaka' => Assets.backgrounds.levelOsaka,
        'kyoto' => Assets.backgrounds.levelKyoto,
        'hokkaido' => Assets.backgrounds.levelHokkaido,
        'fukuoka' => Assets.backgrounds.levelFukuoka,
        'okinawa' => Assets.backgrounds.levelOkinawa,
        'omakase' => Assets.backgrounds.levelOmakase,
        'nagoya' => Assets.backgrounds.levelNagoya,
        'hiroshima' => Assets.backgrounds.levelHiroshima,
        'kanazawa' => Assets.backgrounds.levelKanazawa,
        'sendai' => Assets.backgrounds.levelSendai,
        'kobe' => Assets.backgrounds.levelKobe,
        'nara' => Assets.backgrounds.levelNara,
        'ginza' => Assets.backgrounds.levelGinza,
        _ => Assets.backgrounds.bg,
      };

  /// Shop icon by id; the ids are the ones the game data uses.
  static AssetGenImage shop(String id) => switch (id) {
        'tsukiji' => Assets.ui.shops.tsukiji,
        'osaka' => Assets.ui.shops.osaka,
        'kyoto' => Assets.ui.shops.kyoto,
        'hokkaido' => Assets.ui.shops.hokkaido,
        'fukuoka' => Assets.ui.shops.fukuoka,
        'okinawa' => Assets.ui.shops.okinawa,
        'omakase' => Assets.ui.shops.omakase,
        'nagoya' => Assets.ui.shops.nagoya,
        'hiroshima' => Assets.ui.shops.hiroshima,
        'kanazawa' => Assets.ui.shops.kanazawa,
        'sendai' => Assets.ui.shops.sendai,
        'kobe' => Assets.ui.shops.kobe,
        'nara' => Assets.ui.shops.nara,
        'ginza' => Assets.ui.shops.ginza,
        _ => throw ArgumentError.value(id, 'id', 'no shop icon'),
      };

  /// Furniture icon by id; the ids are the ones the game data uses.
  static AssetGenImage furniture(String id) => switch (id) {
        'lantern' => Assets.sprites.furniture.lantern,
        'stool' => Assets.sprites.furniture.stool,
        'noren' => Assets.sprites.furniture.noren,
        'sign' => Assets.sprites.furniture.sign,
        'plant' => Assets.sprites.furniture.plant,
        'luckycat' => Assets.sprites.furniture.luckycat,
        'aquarium' => Assets.sprites.furniture.aquarium,
        'conveyor' => Assets.sprites.furniture.conveyor,
        'kadomatsu' => Assets.sprites.furniture.kadomatsu,
        'taiko' => Assets.sprites.furniture.taiko,
        'sake' => Assets.sprites.furniture.sake,
        'trophy' => Assets.sprites.furniture.trophy,
        _ => throw ArgumentError.value(id, 'id', 'no furniture icon'),
      };

  /// A square sprite decoded near its display size (3x, like [BoosterIcon]):
  /// the sources are 192-292px but icons are drawn at 16-44.
  static Widget sized(ImageProvider image, double size) => Image(
        image: ResizeImage(image, width: (size * 3).round()),
        width: size,
        height: size,
      );

  static const ink = Color(0xFF4A2E1B);
  static const paper = Color(0xFFFBF1DC);

  /// Wooden board with wave corners; stretches without distorting the frame.
  static BoxDecoration panelDecoration() => BoxDecoration(
        image: DecorationImage(
          image: panel,
          fit: BoxFit.fill,
          // The sprite is 890px wide: `scale` shrinks it to logical size and
          // centerSlice is expressed in those logical units.
          scale: 3,
          centerSlice: const Rect.fromLTRB(55, 42.5, 241.5, 95),
        ),
      );

  /// Wooden plank sprite stretched as a nine-patch so the rounded ends stay
  /// undistorted.
  static BoxDecoration plankSpriteDecoration() => BoxDecoration(
        image: DecorationImage(
          image: Assets.ui.plank.provider(),
          fit: BoxFit.fill,
          // 829x230 sprite: scale shrinks it to ~138x38 logical units and
          // centerSlice is expressed in those units.
          scale: 6,
          centerSlice: const Rect.fromLTRB(16, 16, 122, 22),
        ),
      );

  /// Flat cream chip with a thin ink outline. Replaces the old wood-grain
  /// plank so only the big panels carry the wood-and-wave frame.
  static BoxDecoration plankDecoration() => BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ink.withValues(alpha: 0.55), width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      );
}

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

/// Round red button with an icon on it.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton(
      {super.key, this.icon, this.sprite, required this.onPressed})
      : assert(icon != null || sprite != null);
  final IconData? icon;

  /// Sprite drawn instead of [icon].
  final Widget? sprite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Audio.play(Sfx.tap);
        onPressed();
      },
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.fromLTRB(12, 8, 0, 0),
        decoration: BoxDecoration(
          image: DecorationImage(image: UiArt.buttonRound, fit: BoxFit.fill),
        ),
        child: Center(child: sprite ?? Icon(icon, color: Colors.white)),
      ),
    );
  }
}

/// Red heart sprite followed by an amount.
class HeartAmount extends StatelessWidget {
  const HeartAmount(this.text, {super.key, this.size = 20, this.style});
  final String text;
  final double size;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UiArt.sized(UiArt.heart, size),
        const SizedBox(width: 4),
        Text(text, style: style),
      ],
    );
  }
}

/// Gold coin sprite followed by an amount.
class CoinAmount extends StatelessWidget {
  const CoinAmount(this.amount, {super.key, this.size = 16, this.style});
  final int amount;
  final double size;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UiArt.sized(UiArt.coin, size),
        const SizedBox(width: 4),
        Text('$amount', style: style),
      ],
    );
  }
}

/// Reward amounts with the coin and booster sprites used elsewhere in the UI.
class RewardAmount extends StatelessWidget {
  const RewardAmount(
      {super.key,
      required this.coins,
      this.booster,
      this.qty = 0,
      this.size = 16,
      this.style});

  final int coins;
  final String? booster;
  final int qty;
  final double size;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final kind = Booster.values.where((b) => b.name == booster).firstOrNull;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (coins > 0) CoinAmount(coins, size: size, style: style),
        if (booster != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (kind != null)
                BoosterIcon(kind, size: size)
              else
                UiArt.sized(UiArt.gift, size),
              const SizedBox(width: 4),
              Text('×$qty', style: style),
            ],
          ),
      ],
    );
  }
}

extension SizedAsset on AssetGenImage {
  /// Square image of [size] decoded near that size; see [UiArt.sized].
  Image sized(double size) => image(
        width: size,
        height: size,
        cacheWidth: (size * 3).round(),
      );
}
