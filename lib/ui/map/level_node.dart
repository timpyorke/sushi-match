import 'package:flutter/material.dart';

import '../../core/piece.dart';
import '../../game/piece_painter.dart';
import '../ui_art.dart';

/// One level on the map: a sushi plate (or a lock), its number and, once
/// cleared, the stars earned.
class LevelNode extends StatelessWidget {
  const LevelNode(
      {super.key,
      required this.level,
      required this.size,
      required this.locked,
      required this.done,
      required this.stars,
      required this.current,
      required this.onTap});
  final int level;
  final double size;
  final bool locked;
  final bool done;

  /// Best stars earned on this level (0-3).
  final int stars;

  /// The next level to play: gets a glow.
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kind = PieceKind.values[(level - 1) % PieceKind.values.length];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: current
                ? const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Color(0xCCFFD54F),
                          blurRadius: 18,
                          spreadRadius: 4)
                    ],
                  )
                : null,
            child: locked
                ? Icon(Icons.lock, size: size * 0.6, color: Colors.black54)
                : CustomPaint(painter: _SushiPainter(kind)),
          ),
          const SizedBox(height: 2),
          Container(
            width: size + 4,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: locked ? Colors.grey.shade400 : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color:
                      locked ? Colors.grey.shade600 : const Color(0xFFB71C2C),
                  width: 2.5),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('$level',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          if (done)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 1; i <= 3; i++)
                    StarIcon(
                        size: (size / 3).clamp(10.0, 16.0), lit: i <= stars),
                ],
              ),
            )
          else
            SizedBox(height: (size / 3).clamp(10.0, 16.0) + 2),
        ],
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
