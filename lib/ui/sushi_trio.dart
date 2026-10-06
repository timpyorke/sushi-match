import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/piece.dart';
import '../game/piece_painter.dart';

/// The three sushi used as the logo mark.
List<PieceKind> get logoKinds => [
      PieceKind.values[0],
      PieceKind.values[1 % PieceKind.values.length],
      PieceKind.values[2 % PieceKind.values.length],
    ];

/// One sushi sprite drawn at [size].
class KindSprite extends StatelessWidget {
  const KindSprite(this.kind, {super.key, this.size = 72});
  final PieceKind kind;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _KindPainter(kind)),
      );
}

/// Vertical offset of the i-th sushi in the bobbing wave at animation value [t].
double trioBob(double t, int i) =>
    -10 * math.sin((t + i / 3) * 2 * math.pi);

/// Three sushi bobbing in a wave above the title.
class SushiTrio extends StatelessWidget {
  const SushiTrio({super.key, required this.animation, this.size = 72});
  final Animation<double> animation;
  final double size;

  @override
  Widget build(BuildContext context) {
    final kinds = logoKinds;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < kinds.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Transform.translate(
                offset: Offset(0, trioBob(animation.value, i)),
                child: KindSprite(kinds[i], size: size),
              ),
            ),
        ],
      ),
    );
  }
}

class _KindPainter extends CustomPainter {
  _KindPainter(this.kind);
  final PieceKind kind;

  @override
  void paint(Canvas canvas, Size size) =>
      PiecePainter.paint(canvas, size.width, kind, null);

  @override
  bool shouldRepaint(_KindPainter old) => old.kind != kind;
}
