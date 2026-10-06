import 'dart:ui';

import 'package:flame/components.dart';

import '../core/piece.dart';
import 'piece_painter.dart';

class PieceComponent extends PositionComponent {
  PieceComponent({
    required this.pieceId,
    required this.kind,
    required this.special,
    this.ice = 0,
    required double cellSize,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2.all(cellSize),
          anchor: Anchor.center,
        );

  final int pieceId;
  final PieceKind? kind;
  SpecialType? special;

  /// Ice layers caging the piece (0 = free).
  int ice;

  static final _iceFill = Paint();
  static final _iceEdge = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  static final _iceGlint = Paint()
    ..color = const Color(0xCCFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  static final _iceDot = Paint()..color = const Color(0xFF2E7FA8);

  @override
  void render(Canvas canvas) {
    PiecePainter.paint(canvas, size.x, kind, special);
    if (ice == 0) return;
    final s = size.x;
    final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, s, s).deflate(s * 0.05), Radius.circular(s * 0.2));
    // More layers read as thicker, cloudier ice.
    _iceFill.color = Color.fromARGB(70 + 40 * ice.clamp(1, 3), 170, 225, 250);
    canvas.drawRRect(rr, _iceFill);
    canvas.drawRRect(rr, _iceEdge);
    canvas.drawLine(
        Offset(s * 0.22, s * 0.36), Offset(s * 0.36, s * 0.22), _iceGlint);
    canvas.drawLine(
        Offset(s * 0.22, s * 0.5), Offset(s * 0.5, s * 0.22), _iceGlint);
    for (var i = 0; i < ice; i++) {
      canvas.drawCircle(
          Offset(s * (0.5 - 0.09 * (ice - 1) + 0.18 * i), s * 0.86),
          s * 0.045,
          _iceDot);
    }
  }
}
