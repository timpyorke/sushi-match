import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/piece.dart';
import 'obstacle_art.dart';
import 'piece_painter.dart';

/// Padlock tinted with the colour that must be matched to open the cell.
/// Drawn over the piece (priority above pieces, below the cat).
class KeyLockBadge extends PositionComponent {
  KeyLockBadge(
      {required this.kind, required double cellSize, required Vector2 position})
      : super(
            position: position,
            size: Vector2.all(cellSize),
            anchor: Anchor.center,
            priority: 5) {
    final tint = PiecePainter.colors[kind]!;
    _frame = Paint()
      ..color = tint.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    _body = Paint()..color = tint;
  }

  final PieceKind kind;

  late final Paint _frame;
  late final Paint _body;
  static final _shackle = Paint()
    ..color = const Color(0xFFFFF1D6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.6;
  static final _edge = Paint()
    ..color = const Color(0xFF2B211C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;

  @override
  void render(Canvas canvas) {
    final s = size.x;
    // A faint tinted frame marks the whole locked cell.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, s, s).deflate(2), Radius.circular(s * 0.16)),
        _frame);
    final c = Offset(s * 0.2, s * 0.22);
    if (ObstacleArt.ready) {
      ObstacleArt.draw(canvas, ObstacleSprite.key,
          Rect.fromCenter(center: c, width: s * 0.36, height: s * 0.36));
      return;
    }
    canvas.drawArc(
        Rect.fromCenter(center: c.translate(0, -4), width: 11, height: 14),
        math.pi,
        math.pi,
        false,
        _shackle);
    final rr = RRect.fromRectAndRadius(
        Rect.fromCenter(center: c.translate(0, 3), width: 17, height: 13),
        const Radius.circular(3));
    canvas.drawRRect(rr, _body);
    canvas.drawRRect(rr, _edge);
  }
}

/// Teleporter marker. The entry is a swirling dark vortex filling its cell;
/// the exit is a bright ring around the cell it feeds.
class PortalBadge extends PositionComponent {
  PortalBadge(
      {required this.entry,
      required this.tint,
      required double cellSize,
      required Vector2 position})
      : super(
            position: position,
            size: Vector2.all(cellSize),
            anchor: Anchor.center,
            priority: entry ? 1 : 6) {
    final hue = _hues[tint % _hues.length];
    _swirl = Paint()
      ..color = hue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    _ring = Paint()
      ..color = hue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    _spin = Paint()
      ..color = hue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
  }

  final bool entry;

  static final _vortex = Paint()..color = const Color(0xFF1B1430);
  late final Paint _swirl;
  late final Paint _ring;
  late final Paint _spin;

  /// Which pair this belongs to, for colour.
  final int tint;
  double _t = 0;

  static const _hues = [
    Color(0xFF8E5BD6),
    Color(0xFF2AA7A0),
    Color(0xFFE08A2E)
  ];

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final s = size.x;
    final c = Offset(s / 2, s / 2);
    if (ObstacleArt.ready) {
      if (entry) {
        ObstacleArt.draw(canvas, ObstacleSprite.portal,
            Rect.fromLTWH(0, 0, s, s).deflate(s * 0.04),
            rot: _t * 1.5);
        return;
      }
      // Exit: the same gate, smaller and tinted ring-like, in the corner.
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(0, 0, s, s).deflate(2), Radius.circular(s * 0.18)),
          _ring);
      ObstacleArt.draw(
          canvas,
          ObstacleSprite.portal,
          Rect.fromCenter(
              center: Offset(s * 0.8, s * 0.2),
              width: s * 0.3,
              height: s * 0.3),
          rot: _t * 4);
      return;
    }
    if (entry) {
      canvas.drawCircle(c, s * 0.4, _vortex);
      for (var i = 0; i < 3; i++) {
        final r = s * (0.12 + 0.09 * i);
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), _t * (2 + i) + i,
            math.pi * 1.4, false, _swirl);
      }
      return;
    }
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, s, s).deflate(2), Radius.circular(s * 0.18)),
        _ring);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(s * 0.8, s * 0.2), radius: s * 0.1),
        _t * 4,
        math.pi * 1.5,
        false,
        _spin);
  }
}
