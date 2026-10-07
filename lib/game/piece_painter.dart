import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';

import '../core/piece.dart';

/// Grey-box art: every kind differs by colour AND shape (colour-blind safe,
/// per GDD). Swap for the sprite atlas later without touching game logic.
abstract final class PiecePainter {
  static const colors = <PieceKind, Color>{
    PieceKind.salmon: Color(0xFFFF8A4C),
    PieceKind.maguro: Color(0xFFB71C2C),
    PieceKind.tamago: Color(0xFFF5C842),
    PieceKind.ikura: Color(0xFFFF5A36),
    PieceKind.ebi: Color(0xFFFF9EB5),
    PieceKind.kappa: Color(0xFF4CAF50),
    PieceKind.unagi: Color(0xFF8D5524),
    PieceKind.hotate: Color(0xFFCDB4DB),
    PieceKind.ika: Color(0xFF8EC9E8),
    PieceKind.tako: Color(0xFF3F51B5),
  };

  /// Kinds with a sprite (the first [spriteKinds] values); later kinds are
  /// vector-only.
  static const spriteKinds = 10;

  static final _eye = Paint()..color = const Color(0xFF3B2A20);
  static final _white = Paint()..color = const Color(0xFFFFFFFF);
  static final _nori = Paint()..color = const Color(0xFF1F2A1E);
  static final _outline = Paint()
    ..color = const Color(0xFF3B2A20)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  static final _fills = {
    for (final e in colors.entries) e.key: Paint()..color = e.value,
  };

  /// Shared by every sprite draw (one Paint per frame per piece adds up).
  static final _spritePaint = Paint()..filterQuality = FilterQuality.medium;

  static final _sprites = <PieceKind, Image>{};
  static final _powerSprites = <SpecialType, Image>{};

  static const _powerFiles = {
    SpecialType.knifeRow: 'knife',
    SpecialType.knifeCol: 'knife',
    SpecialType.wasabi: 'wasabi',
    SpecialType.omakase: 'omakase',
    SpecialType.soyFish: 'soyfish',
  };

  static bool get _spritesReady =>
      _sprites.length == spriteKinds && _powerSprites.isNotEmpty;

  /// Loads one 256px sprite per kind (assets/sprites/sushi/<kind>.png) and per power
  /// item. Until they finish, pieces fall back to the vector art.
  static Future<void> loadSprites() async {
    for (final kind in PieceKind.values.take(spriteKinds)) {
      _sprites[kind] ??= await _decode('assets/sprites/sushi/${kind.name}.png');
    }
    for (final e in _powerFiles.entries) {
      _powerSprites[e.key] ??=
          await _decode('assets/sprites/power/${e.value}.png');
    }
  }

  /// Decoded width of piece sprites. The source art is 256px but a cell is at
  /// most ~160 physical px on screen; the smaller texture saves memory and
  /// bandwidth on low-end GPUs.
  static const _spriteSize = 160;

  static Future<Image> _decode(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: _spriteSize);
    return (await codec.getNextFrame()).image;
  }

  static void _powerSprite(Canvas canvas, Rect dst, SpecialType type,
      {double rotation = 0}) {
    final sprite = _powerSprites[type]!;
    final src =
        Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble());
    canvas.save();
    canvas.translate(dst.center.dx, dst.center.dy);
    canvas.rotate(rotation);
    canvas.drawImageRect(
        sprite,
        src,
        Rect.fromCenter(
            center: Offset.zero, width: dst.width, height: dst.height),
        _spritePaint);
    canvas.restore();
  }

  /// Power items stand alone (no sushi underneath). They still match by
  /// colour, so a glow in the kind's colour sits behind the sprite.
  /// Knife art points up-left; rotate it to lie along the row/column it clears.
  static void _specialSprite(
      Canvas canvas, double s, PieceKind kind, SpecialType type) {
    glow(canvas, Offset(s / 2, s / 2), s * 0.36,
        colors[kind]!.withValues(alpha: 0.85), 1 / 3);
    final rotation = switch (type) {
      SpecialType.knifeRow => -math.pi / 4,
      SpecialType.knifeCol => math.pi / 4,
      _ => 0.0,
    };
    _powerSprite(
        canvas, Rect.fromLTWH(s * 0.05, s * 0.05, s * 0.9, s * 0.9), type,
        rotation: rotation);
  }

  static void _sprite(Canvas canvas, Rect dst, PieceKind kind) {
    final img = _sprites[kind]!;
    canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        dst,
        _spritePaint);
  }

  static final _glows = <(int, double), Image>{};

  /// Radius of the disc baked into a glow image, in pixels.
  static const _glowBake = 48.0;

  /// Draws a soft disc of radius [r] at [c], blurred by [blur] × [r].
  ///
  /// A live `MaskFilter.blur` costs a Gaussian pass on the GPU every frame;
  /// here each colour/blur pair is blurred once into an image and then just
  /// stretched into place.
  static void glow(
      Canvas canvas, Offset c, double r, Color color, double blur) {
    final img = _glows[(color.toARGB32(), blur)] ??= _bakeGlow(color, blur);
    canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromCircle(center: c, radius: r * (1 + 3 * blur)),
        _spritePaint);
  }

  static Image _bakeGlow(Color color, double blur) {
    final half = _glowBake * (1 + 3 * blur);
    final recorder = PictureRecorder();
    Canvas(recorder).drawCircle(
        Offset(half, half),
        _glowBake,
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, _glowBake * blur));
    final picture = recorder.endRecording();
    final side = (2 * half).ceil();
    final img = picture.toImageSync(side, side);
    picture.dispose();
    return img;
  }

  /// Delivery ingredient: a smiling rice ball on a golden glow.
  static void paintIngredient(Canvas canvas, double s) {
    final tri = Path()
      ..moveTo(s * 0.5, s * 0.2)
      ..lineTo(s * 0.82, s * 0.78)
      ..lineTo(s * 0.18, s * 0.78)
      ..close();
    glow(canvas, Offset(s / 2, s / 2), s * 0.44, const Color(0xCCFFD54F),
        0.1 / 0.44);
    final round = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = s * 0.12;
    canvas.drawPath(tri, round..color = const Color(0xFFFFFDF5));
    canvas.drawPath(tri, Paint()..color = const Color(0xFFFFFDF5));
    canvas.save();
    canvas.clipPath(tri);
    canvas.drawRect(Rect.fromLTWH(s * 0.1, s * 0.62, s * 0.8, s * 0.2), _nori);
    canvas.restore();
    canvas.drawPath(tri, _outline..strokeJoin = StrokeJoin.round);
    canvas.drawCircle(Offset(s * 0.43, s * 0.5), s * 0.035, _eye);
    canvas.drawCircle(Offset(s * 0.57, s * 0.5), s * 0.035, _eye);
  }

  static void paint(
      Canvas canvas, double s, PieceKind? kind, SpecialType? special) {
    final body = Rect.fromLTWH(s * 0.1, s * 0.1, s * 0.8, s * 0.8);
    final c = body.center;

    if (special != null) {
      // Blur of 6 at the 64px cell the art was tuned for.
      glow(canvas, c, s * 0.5, const Color(0x99FFF59D), 6 / 32);
    }

    if (kind == null) {
      if (_powerSprites.isNotEmpty) {
        _powerSprite(canvas, Rect.fromLTWH(0, 0, s, s), SpecialType.omakase);
      } else {
        _plate(canvas, c, s);
      }
      return;
    }

    if (_spritesReady) {
      if (special != null) {
        _specialSprite(canvas, s, kind, special);
        return;
      }
      if (kind.index < spriteKinds) {
        _sprite(canvas, Rect.fromLTWH(0, 0, s, s), kind);
        _special(canvas, s, body, c, special);
        return;
      }
    }

    final fill = _fills[kind]!;
    switch (kind) {
      case PieceKind.salmon:
        final rr = RRect.fromRectAndRadius(body, Radius.circular(s * 0.18));
        canvas.drawRRect(rr, fill);
        canvas.save();
        canvas.clipRRect(rr);
        final stripe = Paint()
          ..color = const Color(0xCCFFFFFF)
          ..strokeWidth = s * 0.05;
        for (var i = -1; i <= 1; i++) {
          final x = c.dx + i * s * 0.24;
          canvas.drawLine(Offset(x - s * 0.2, body.bottom),
              Offset(x + s * 0.2, body.top), stripe);
        }
        canvas.restore();
      case PieceKind.maguro:
        canvas.drawRRect(
            RRect.fromRectAndRadius(body, Radius.circular(s * 0.18)), fill);
      case PieceKind.tamago:
        canvas.drawRRect(
            RRect.fromRectAndRadius(body, Radius.circular(s * 0.05)), fill);
        canvas.drawRect(
            Rect.fromCenter(center: c, width: s * 0.18, height: body.height),
            _nori);
      case PieceKind.ikura:
        canvas.drawCircle(c, body.width / 2, _nori);
        canvas.drawCircle(c, body.width * 0.4, fill);
        final egg = Paint()..color = const Color(0xFFFFB199);
        for (var i = 0; i < 5; i++) {
          final a = i * 2 * math.pi / 5 + math.pi / 2;
          canvas.drawCircle(
              c + Offset(math.cos(a), math.sin(a)) * (s * 0.2), s * 0.06, egg);
        }
      case PieceKind.ebi:
        canvas.drawArc(
          body.deflate(s * 0.12),
          math.pi * 0.15,
          math.pi * 1.4,
          false,
          Paint()
            ..color = fill.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.24
            ..strokeCap = StrokeCap.round,
        );
      case PieceKind.kappa:
        canvas.drawCircle(c, body.width / 2, _nori);
        canvas.drawCircle(c, body.width * 0.38, _white);
        canvas.drawCircle(c, body.width * 0.2, fill);
      case PieceKind.unagi:
        final slab = Rect.fromCenter(
            center: c, width: body.width, height: body.height * 0.62);
        final rr = RRect.fromRectAndRadius(slab, Radius.circular(s * 0.14));
        canvas.drawRRect(rr, fill);
        canvas.save();
        canvas.clipRRect(rr);
        final sauce = Paint()
          ..color = const Color(0xCC2B1408)
          ..strokeWidth = s * 0.06;
        for (var i = -1; i <= 1; i++) {
          final x = c.dx + i * s * 0.26;
          canvas.drawLine(Offset(x - s * 0.1, slab.bottom),
              Offset(x + s * 0.1, slab.top), sauce);
        }
        canvas.restore();
        canvas.drawRect(
            Rect.fromCenter(center: c, width: s * 0.1, height: slab.height),
            _nori);
      case PieceKind.hotate:
        final base = Offset(c.dx, body.bottom - s * 0.04);
        final fan = Path()
          ..moveTo(base.dx, base.dy)
          ..arcTo(Rect.fromCircle(center: base, radius: body.width * 0.55),
              math.pi * 1.1, math.pi * 0.8, false)
          ..close();
        canvas.drawPath(fan, fill);
        final rib = Paint()
          ..color = const Color(0xFF9B7FB5)
          ..strokeWidth = s * 0.03;
        for (var i = 0; i < 5; i++) {
          final a = math.pi * (1.1 + 0.8 * (i + 0.5) / 5);
          canvas.drawLine(
              base, base + Offset(math.cos(a), math.sin(a)) * (s * 0.44), rib);
        }
        canvas.drawPath(fan, _outline);
      case PieceKind.ika:
        final rr = RRect.fromRectAndRadius(body, Radius.circular(s * 0.12));
        canvas.drawRRect(rr, fill);
        canvas.save();
        canvas.clipRRect(rr);
        final cut = Paint()
          ..color = const Color(0xCCFFFFFF)
          ..strokeWidth = s * 0.035;
        for (var i = -3; i <= 3; i++) {
          final d = i * s * 0.2;
          canvas.drawLine(Offset(body.left + d, body.top),
              Offset(body.left + d + body.height, body.bottom), cut);
          canvas.drawLine(Offset(body.right + d, body.top),
              Offset(body.right + d - body.height, body.bottom), cut);
        }
        canvas.restore();
      case PieceKind.tako:
        final head = Rect.fromCenter(
            center: Offset(c.dx, c.dy - s * 0.1),
            width: body.width,
            height: body.height * 0.75);
        canvas.drawArc(head, math.pi, math.pi, true, fill);
        final legs = Paint()
          ..color = fill.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.15
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 3; i++) {
          final x = body.left + body.width * (0.2 + 0.3 * i);
          canvas.drawPath(
              Path()
                ..moveTo(x, c.dy - s * 0.1)
                ..quadraticBezierTo(x + s * 0.1 * (i.isEven ? 1 : -1),
                    c.dy + s * 0.2, x, body.bottom - s * 0.04),
              legs);
        }
        final sucker = Paint()..color = const Color(0xCCFFFFFF);
        for (var i = 0; i < 3; i++) {
          canvas.drawCircle(
              Offset(body.left + body.width * (0.2 + 0.3 * i), c.dy + s * 0.16),
              s * 0.03,
              sucker);
        }
    }

    // Kawaii eyes.
    final ey = c.dy - s * 0.06;
    canvas.drawCircle(Offset(c.dx - s * 0.12, ey), s * 0.045, _eye);
    canvas.drawCircle(Offset(c.dx + s * 0.12, ey), s * 0.045, _eye);

    _special(canvas, s, body, c, special);
  }

  static void _special(
      Canvas canvas, double s, Rect body, Offset c, SpecialType? special) {
    switch (special) {
      case SpecialType.knifeRow:
        _knife(canvas, c, s, horizontal: true);
      case SpecialType.knifeCol:
        _knife(canvas, c, s, horizontal: false);
      case SpecialType.wasabi:
        final at = Offset(body.right - s * 0.06, body.top + s * 0.06);
        canvas.drawCircle(
            at, s * 0.15, Paint()..color = const Color(0xFF8BC34A));
        canvas.drawCircle(at, s * 0.15, _outline);
      case SpecialType.soyFish:
        _fish(canvas, Offset(body.right - s * 0.1, body.bottom - s * 0.08), s);
      case SpecialType.omakase:
      case null:
        break;
    }
  }

  static void _knife(Canvas canvas, Offset c, double s,
      {required bool horizontal}) {
    final r = horizontal
        ? Rect.fromCenter(center: c, width: s * 0.92, height: s * 0.12)
        : Rect.fromCenter(center: c, width: s * 0.12, height: s * 0.92);
    final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.05));
    canvas.drawRRect(rr, Paint()..color = const Color(0xFFE8EAED));
    canvas.drawRRect(rr, _outline);
  }

  static void _fish(Canvas canvas, Offset at, double s) {
    final paint = Paint()..color = const Color(0xFF6D3B1F);
    canvas.drawOval(
        Rect.fromCenter(center: at, width: s * 0.3, height: s * 0.16), paint);
    final tail = Path()
      ..moveTo(at.dx + s * 0.12, at.dy)
      ..lineTo(at.dx + s * 0.22, at.dy - s * 0.08)
      ..lineTo(at.dx + s * 0.22, at.dy + s * 0.08)
      ..close();
    canvas.drawPath(tail, paint);
  }

  static void _plate(Canvas canvas, Offset c, double s) {
    canvas.drawCircle(c, s * 0.42, _white);
    canvas.drawCircle(c, s * 0.42, _outline);
    final kinds = colors.values.toList();
    for (var i = 0; i < kinds.length; i++) {
      final a = i * 2 * math.pi / kinds.length;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * (s * 0.24),
          s * 0.08, Paint()..color = kinds[i]);
    }
  }
}
