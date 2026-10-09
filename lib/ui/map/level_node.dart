import 'package:flutter/material.dart';

import '../../core/piece.dart';
import '../../game/piece_painter.dart';
import '../l10n.dart';
import '../ui_art.dart';
import 'map_art.dart';

/// One level on the map: a sushi plate (or a lock) and, once cleared, the
/// stars earned, with its number on a tag under the plate.
class LevelNode extends StatelessWidget {
  const LevelNode(
      {super.key,
      required this.level,
      required this.size,
      required this.locked,
      required this.done,
      required this.stars,
      required this.current,
      this.boss = false,
      this.art,
      required this.onTap});
  final int level;
  final double size;
  final bool locked;
  final bool done;

  /// Best stars earned on this level (0-3).
  final int stars;

  /// The next level to play: gets a glow.
  final bool current;

  /// Last level of its restaurant: shows a pennant.
  final bool boss;

  /// Decoded map sprites; `null` while loading (shapes are drawn instead).
  final MapArt? art;
  final VoidCallback onTap;

  Widget _star(bool lit, double s) {
    final img = art?[lit ? 'star_lit' : 'star_dim'];
    if (img == null) return StarIcon(size: s, lit: lit);
    return SizedBox.square(
        dimension: s, child: RawImage(image: img, fit: BoxFit.contain));
  }

  /// The plate with the sushi (or a padlock) on it.
  Widget _plate() {
    final a = art;
    final name = locked
        ? 'plate_locked'
        : current
            ? 'plate_current'
            : 'plate';
    final img = a == null ? null : a[name];
    if (a == null || img == null) {
      return DecoratedBox(
        decoration: current
            ? const BoxDecoration(shape: BoxShape.circle, boxShadow: [
                BoxShadow(
                    color: Color(0xCCFFD54F), blurRadius: 18, spreadRadius: 4)
              ])
            : const BoxDecoration(),
        child: locked
            ? Icon(Icons.lock, size: size * 0.6, color: Colors.black54)
            : CustomPaint(
                painter: _SushiPainter(
                    PieceKind.values[(level - 1) % PieceKind.values.length])),
      );
    }
    final flag = boss && !locked ? a['flag_boss'] : null;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: RawImage(image: img, fit: BoxFit.contain)),
        if (!locked)
          Padding(
            padding: EdgeInsets.all(size * 0.2),
            child: CustomPaint(
                painter: _SushiPainter(
                    PieceKind.values[(level - 1) % PieceKind.values.length])),
          ),
        if (a['number_tag'] != null)
          // The sprite is a square canvas with the pill in its middle, so the
          // square is centred on the plate's bottom edge.
          Positioned(
              left: size * 0.1,
              width: size * 0.8,
              height: size * 0.8,
              bottom: -size * 0.4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                      child:
                          RawImage(image: a['number_tag'], fit: BoxFit.fill)),
                  SizedBox(
                    width: size * 0.45,
                    height: size * 0.24,
                    child: FittedBox(
                      child: Text('$level',
                          style: const TextStyle(
                              color: UiArt.ink, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )),
        if (current && a['marker'] != null)
          Positioned(
              left: size * 0.2,
              right: size * 0.2,
              top: -size * 0.55,
              height: size * 0.6,
              child: RawImage(image: a['marker'], fit: BoxFit.contain)),
        if (flag != null)
          Positioned(
              right: -size * 0.15,
              top: -size * 0.25,
              width: size * 0.5,
              height: size * 0.5,
              child: RawImage(image: flag, fit: BoxFit.contain)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: L10n.t('levelN', {'n': level}),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The next level stands out; the ones still out of reach step back.
            SizedBox(
                width: size,
                height: size,
                child: Transform.scale(
                    scale: current
                        ? 1.2
                        : locked
                            ? 0.82
                            : 1,
                    child: _plate())),
            SizedBox(height: size * 0.16),
            if (done)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 1; i <= 3; i++)
                      _star(i <= stars, (size / 3).clamp(10.0, 16.0)),
                  ],
                ),
              )
            else
              SizedBox(height: (size / 3).clamp(10.0, 16.0) + 2),
          ],
        ),
      ),
    );
  }
}

class _SushiPainter extends CustomPainter {
  _SushiPainter(this.kind);
  final PieceKind kind;

  @override
  void paint(Canvas canvas, Size size) =>
      PiecePainter.paint(canvas, size.width, kind, null);

  @override
  bool shouldRepaint(_SushiPainter old) => old.kind != kind;
}
