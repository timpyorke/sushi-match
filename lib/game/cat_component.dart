import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../gen/assets.gen.dart';

/// Joker the Boss Cat's animations (four frames each).
enum CatAnim {
  idle(4, loop: true),
  prowl(8),
  eat(10),
  hit(12),
  flee(10);

  const CatAnim(this.fps, {this.loop = false});
  final double fps;

  /// Loops until replaced; the others play once and fall back to idle.
  final bool loop;
}

/// Decoded Joker frames. Until [load] finishes (and in tests that never call
/// it) [ready] is false and [CatComponent] draws its vector stand-in.
abstract final class CatArt {
  static const frameCount = 4;

  static List<AssetGenImage> _files(CatAnim anim) {
    final j = Assets.sprites.obstacles.a18BossCatJoker;
    return switch (anim) {
      CatAnim.idle => [j.idle0, j.idle1, j.idle2, j.idle3],
      CatAnim.prowl => [j.prowl0, j.prowl1, j.prowl2, j.prowl3],
      CatAnim.eat => [j.eat0, j.eat1, j.eat2, j.eat3],
      CatAnim.hit => [j.hit0, j.hit1, j.hit2, j.hit3],
      CatAnim.flee => [j.flee0, j.flee1, j.flee2, j.flee3],
    };
  }

  static final _frames = <CatAnim, List<Image>>{};

  static bool get ready => _frames.length == CatAnim.values.length;

  static Future<void> load() async {
    for (final anim in CatAnim.values) {
      if (_frames.containsKey(anim)) continue;
      final images = <Image>[];
      for (final file in _files(anim)) {
        final data = await rootBundle.load(file.path);
        final codec = await instantiateImageCodec(data.buffer.asUint8List());
        images.add((await codec.getNextFrame()).image);
      }
      _frames[anim] = images;
    }
  }

  static Image frame(CatAnim anim, int i) => _frames[anim]![i];
}

/// A thieving cat prowling the board, drawn over the pieces. Uses the Joker
/// sprites once [CatArt] is loaded, otherwise grey-box vector art like the
/// rest of the pieces.
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
  CatAnim _anim = CatAnim.idle;
  double _animT = 0;

  static final _spritePaint = Paint()..filterQuality = FilterQuality.medium;

  /// Plays [anim]; one-shot animations return to idle when they finish.
  void play(CatAnim anim) {
    _anim = anim;
    _animT = 0;
  }

  /// The prowl and flee sprites face left; true mirrors them to face right.
  bool faceRight = false;

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
    _animT += dt;
    // Flee holds its last frame until the cat leaves the board.
    if (!_anim.loop &&
        _anim != CatAnim.flee &&
        _animT * _anim.fps >= CatArt.frameCount) {
      play(CatAnim.idle);
    }
  }

  @override
  void render(Canvas canvas) {
    final s = size.x;
    if (CatArt.ready) {
      final f = (_animT * _anim.fps).floor();
      final i = _anim == CatAnim.flee
          ? f.clamp(0, CatArt.frameCount - 1)
          : f % CatArt.frameCount;
      final img = CatArt.frame(_anim, i);
      // Little hops while prowling.
      final hop = _anim == CatAnim.prowl
          ? -s * 0.06 * math.sin(_animT * _anim.fps * math.pi).abs()
          : 0.0;
      canvas.save();
      if (faceRight) {
        canvas.translate(s, 0);
        canvas.scale(-1, 1);
      }
      canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          Rect.fromLTWH(0, hop, s, s),
          _spritePaint);
      canvas.restore();
      _pips(canvas, s);
      return;
    }
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
    _pips(canvas, s);
  }

  /// One dot per scare the cat has left.
  void _pips(Canvas canvas, double s) {
    for (var i = 0; i < hp; i++) {
      canvas.drawCircle(Offset(s * (0.5 + 0.14 * (i - (hp - 1) / 2)), s * 0.94),
          s * 0.05, _pip);
    }
  }
}
