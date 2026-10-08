import 'package:flutter/material.dart';

import '../services/audio.dart';
import '../services/wallet.dart';
import 'ui_art.dart';

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
