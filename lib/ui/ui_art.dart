import 'package:flutter/material.dart';

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
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/ui/plank.png'),
          fit: BoxFit.fill,
          // 829x230 sprite: scale shrinks it to ~138x38 logical units and
          // centerSlice is expressed in those units.
          scale: 6,
          centerSlice: Rect.fromLTRB(16, 16, 122, 22),
        ),
      ),
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
  static const panel = AssetImage('assets/ui/panel.png');
  static const heart = AssetImage('assets/ui/heart.png');
  static const buttonRound = AssetImage('assets/ui/button_round.png');
  static const star = AssetImage('assets/ui/star.png');
  static const coin = AssetImage('assets/ui/coin.png');

  static const ink = Color(0xFF4A2E1B);
  static const paper = Color(0xFFFBF1DC);

  /// Wooden board with wave corners; stretches without distorting the frame.
  static BoxDecoration panelDecoration() => const BoxDecoration(
        image: DecorationImage(
          image: panel,
          fit: BoxFit.fill,
          // Sprites are ~1200px wide: `scale` shrinks them to logical size and
          // centerSlice is expressed in those logical units.
          scale: 4,
          centerSlice: Rect.fromLTRB(55, 42.5, 241.5, 95),
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

/// Booster sprite from assets/sprites/boosters/ (the starter boosters use the power
/// sprites in assets/sprites/power/).
class BoosterIcon extends StatelessWidget {
  const BoosterIcon(this.booster, {super.key, this.size = 32});
  final Booster booster;
  final double size;

  static const _sprites = {
    Booster.extraMoves: 'sprites/boosters/hourglass',
    Booster.chopsticks: 'sprites/boosters/chopsticks',
    Booster.freeSwap: 'sprites/boosters/swap',
    Booster.shuffle: 'sprites/boosters/shuffle',
    Booster.starterKnife: 'sprites/power/knife',
    Booster.starterWasabi: 'sprites/power/wasabi',
  };

  @override
  Widget build(BuildContext context) {
    final sprite = _sprites[booster];
    if (sprite == null) return SizedBox(width: size, height: size);
    return Image.asset('assets/$sprite.png',
        width: size,
        height: size,
        // Sprites are 192-256px; decode near display size.
        cacheWidth: (size * 3).round());
  }
}

/// Shopping cart sprite (assets/ui/shopping.png).
class ShopIcon extends StatelessWidget {
  const ShopIcon({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset('assets/ui/shopping.png',
      width: size, height: size, cacheWidth: (size * 3).round());
}

/// Gold star, greyed out when [lit] is false.
class StarIcon extends StatelessWidget {
  const StarIcon({super.key, this.size = 20, this.lit = true});
  final double size;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final img = Image(image: UiArt.star, width: size, height: size);
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
      {super.key, required this.icon, required this.onPressed});
  final IconData icon;
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
        decoration: const BoxDecoration(
          image: DecorationImage(image: UiArt.buttonRound, fit: BoxFit.fill),
        ),
        child: Icon(icon, color: Colors.white),
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
        Image(image: UiArt.heart, width: size, height: size),
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
        Image(image: UiArt.coin, width: size, height: size),
        const SizedBox(width: 4),
        Text('$amount', style: style),
      ],
    );
  }
}
