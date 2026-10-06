import 'dart:math' as math;
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
    this.ingredient = false,
    this.burning = false,
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

  /// A delivery ingredient (drawn as a rice ball, no kind).
  final bool ingredient;

  /// On fire (grill levels).
  bool burning;

  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (burning) _t += dt;
  }

  static final _flameOuter = Paint()..color = const Color(0xFFFF6A1F);
  static final _flameInner = Paint()..color = const Color(0xFFFFD54F);
  static final _flameGlow = Paint()
    ..color = const Color(0x66FF6A1F)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  void _drawFlame(Canvas canvas) {
    final s = size.x;
    canvas.drawCircle(Offset(s / 2, s * 0.45), s * 0.46, _flameGlow);
    for (var i = 0; i < 3; i++) {
      final cx = s * (0.28 + 0.22 * i);
      final h = s * (0.34 + 0.08 * math.sin(_t * 9 + i * 2.1));
      final base = s * 0.62;
      final w = s * 0.13;
      final flame = Path()
        ..moveTo(cx - w, base)
        ..quadraticBezierTo(cx - w * 0.9, base - h * 0.5, cx, base - h)
        ..quadraticBezierTo(cx + w * 0.9, base - h * 0.5, cx + w, base)
        ..close();
      canvas.drawPath(flame, _flameOuter);
      canvas.drawPath(
          Path()
            ..moveTo(cx - w * 0.5, base)
            ..quadraticBezierTo(cx, base - h * 0.75, cx + w * 0.5, base)
            ..close(),
          _flameInner);
    }
  }

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
    if (ingredient) {
      PiecePainter.paintIngredient(canvas, size.x);
    } else {
      PiecePainter.paint(canvas, size.x, kind, special);
    }
    if (burning) _drawFlame(canvas);
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
