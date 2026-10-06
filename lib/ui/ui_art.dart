import 'package:flutter/material.dart';

/// Sprites cut from assets/ui/particle.png.
abstract final class UiArt {
  static const panel = AssetImage('assets/ui/panel.png');
  static const plank = AssetImage('assets/ui/plank.png');
  static const buttonRound = AssetImage('assets/ui/button_round.png');
  static const star = AssetImage('assets/ui/star.png');

  static const ink = Color(0xFF4A2E1B);

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

  static BoxDecoration plankDecoration() => const BoxDecoration(
        image: DecorationImage(
          image: plank,
          fit: BoxFit.fill,
          scale: 5,
          centerSlice: Rect.fromLTRB(12, 12, 154, 34),
        ),
      );
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
      onTap: onPressed,
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
