import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// A thieving cat prowling the board, drawn over the pieces. Grey-box vector
/// art like the rest of the pieces.
class CatComponent extends PositionComponent {
  CatComponent({
    required this.catId,
    required this.hp,
    required double cellSize,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2.all(cellSize),
          anchor: Anchor.center,
          priority: 10,
        );

  final int catId;
  int hp;
  double _t = 0;

  static final _fur = Paint()..color = const Color(0xFFE8A04C);
  static final _furDark = Paint()..color = const Color(0xFFB9722A);
  static final _belly = Paint()..color = const Color(0xFFFFF1D6);
  static final _eye = Paint()..color = const Color(0xFF2B211C);
  static final _nose = Paint()..color = const Color(0xFFE5667E);
  static final _line = Paint()
    ..color = const Color(0xFF2B211C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;
  static final _pip = Paint()..color = const Color(0xFFE5667E);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final s = size.x;
    final bob = math.sin(_t * 4) * s * 0.02;
    canvas.save();
    canvas.translate(0, bob);
    // Tail curling behind.
    canvas.drawPath(
        Path()
          ..moveTo(s * 0.74, s * 0.78)
          ..quadraticBezierTo(s * 0.98, s * 0.74, s * 0.9, s * 0.46),
        _line
          ..strokeWidth = s * 0.09
          ..color = const Color(0xFFB9722A));
    _line
      ..strokeWidth = 1.8
      ..color = const Color(0xFF2B211C);
    final head = Offset(s * 0.5, s * 0.52);
    for (final side in const [-1.0, 1.0]) {
      canvas.drawPath(
          Path()
            ..moveTo(head.dx + side * s * 0.34, head.dy - s * 0.1)
            ..lineTo(head.dx + side * s * 0.26, head.dy - s * 0.42)
            ..lineTo(head.dx + side * s * 0.06, head.dy - s * 0.26)
            ..close(),
          _furDark);
    }
    canvas.drawOval(
        Rect.fromCenter(
            center: head.translate(0, s * 0.04),
            width: s * 0.76,
            height: s * 0.66),
        _fur);
    canvas.drawOval(
        Rect.fromCenter(
            center: head.translate(0, s * 0.16),
            width: s * 0.36,
            height: s * 0.24),
        _belly);
    for (final side in const [-1.0, 1.0]) {
      canvas.drawCircle(
          head.translate(side * s * 0.15, -s * 0.02), s * 0.055, _eye);
      canvas.drawLine(head.translate(side * s * 0.2, s * 0.14),
          head.translate(side * s * 0.4, s * 0.1), _line);
      canvas.drawLine(head.translate(side * s * 0.2, s * 0.18),
          head.translate(side * s * 0.4, s * 0.2), _line);
    }
    canvas.drawCircle(head.translate(0, s * 0.1), s * 0.04, _nose);
    canvas.restore();
    for (var i = 0; i < hp; i++) {
      canvas.drawCircle(Offset(s * (0.5 + 0.14 * (i - (hp - 1) / 2)), s * 0.94),
          s * 0.05, _pip);
    }
  }
}
