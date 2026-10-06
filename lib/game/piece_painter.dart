import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';

import '../core/piece.dart';
import '../core/settings.dart';

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

  /// Kinds with a sprite (first sheet, then second sheet); later kinds are
  /// vector-only.
  static const spriteKinds = 10;
  static const _sheet1Kinds = 6;

  static final _eye = Paint()..color = const Color(0xFF3B2A20);
  static final _white = Paint()..color = const Color(0xFFFFFFFF);
  static final _nori = Paint()..color = const Color(0xFF1F2A1E);
  static final _outline = Paint()
    ..color = const Color(0xFF3B2A20)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  static const _sheetAsset = 'assets/sushi/sushi.png';
  static Image? _sheet;

  static const _sheet2Asset = 'assets/sushi/sushi02.png';
  static Image? _sheet2;

  static const _powerAsset = 'assets/sushi/power-item.png';
  static Image? _power;

  /// Loads the sprite sheets: sushi.png (3 columns x 2 rows) holds the first
  /// six [PieceKind]s, sushi02.png (2x2) the next four. Until they finish,
  /// pieces fall back to the vector art.
  static Future<void> loadSprites() async {
    _sheet ??= await _decode(_sheetAsset);
    _sheet2 ??= await _decode(_sheet2Asset);
    _power ??= await _decode(_powerAsset);
  }

  static Future<Image> _decode(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  /// Power-item sheet is 2x2: knife, wasabi / omakase, soy fish.
  static void _powerSprite(Canvas canvas, Rect dst, SpecialType type,
      {double rotation = 0}) {
    final sheet = _power!;
    final cw = sheet.width / 2, ch = sheet.height / 2;
    final i = switch (type) {
      SpecialType.knifeRow || SpecialType.knifeCol => 0,
      SpecialType.wasabi => 1,
      SpecialType.omakase => 2,
      SpecialType.soyFish => 3,
    };
    final src = Rect.fromLTWH((i % 2) * cw, (i ~/ 2) * ch, cw, ch);
    canvas.save();
    canvas.translate(dst.center.dx, dst.center.dy);
    canvas.rotate(rotation);
    canvas.drawImageRect(
        sheet,
        src,
        Rect.fromCenter(
            center: Offset.zero, width: dst.width, height: dst.height),
        Paint()..filterQuality = FilterQuality.medium);
    canvas.restore();
  }

  /// Power items stand alone (no sushi underneath). They still match by
  /// colour, so a glow in the kind's colour sits behind the sprite.
  /// Knife art points up-left; rotate it to lie along the row/column it clears.
  static void _specialSprite(
      Canvas canvas, double s, PieceKind kind, SpecialType type) {
    canvas.drawCircle(
      Offset(s / 2, s / 2),
      s * 0.36,
      Paint()
        ..color = colors[kind]!.withValues(alpha: 0.85)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.12),
    );
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
    final second = kind.index >= _sheet1Kinds;
    final sheet = second ? _sheet2! : _sheet!;
    final cols = second ? 2 : 3;
    final cw = sheet.width / cols, ch = sheet.height / 2;
    final i = second ? kind.index - _sheet1Kinds : kind.index;
    final src = Rect.fromLTWH((i % cols) * cw, (i ~/ cols) * ch, cw, ch);
    // Sheet cells aren't always square; fit the cell into [dst] undistorted.
    final k = math.min(dst.width / cw, dst.height / ch);
    final fitted =
        Rect.fromCenter(center: dst.center, width: cw * k, height: ch * k);
    canvas.drawImageRect(
        sheet, src, fitted, Paint()..filterQuality = FilterQuality.medium);
  }

  /// Delivery ingredient: a smiling rice ball on a golden glow.
  static void paintIngredient(Canvas canvas, double s) {
    final tri = Path()
      ..moveTo(s * 0.5, s * 0.2)
      ..lineTo(s * 0.82, s * 0.78)
      ..lineTo(s * 0.18, s * 0.78)
      ..close();
    canvas.drawCircle(
      Offset(s / 2, s / 2),
      s * 0.44,
      Paint()
        ..color = const Color(0xCCFFD54F)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.1),
    );
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
      canvas.drawCircle(
        c,
        s * 0.5,
        Paint()
          ..color = const Color(0x99FFF59D)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    if (kind == null) {
      if (_power != null) {
        _powerSprite(canvas, Rect.fromLTWH(0, 0, s, s), SpecialType.omakase);
      } else {
        _plate(canvas, c, s);
      }
      return;
    }

    if (_sheet != null && _sheet2 != null) {
      if (special != null && _power != null) {
        _specialSprite(canvas, s, kind, special);
        _symbol(canvas, s, kind);
        return;
      }
      if (kind.index < spriteKinds) {
        _sprite(canvas, Rect.fromLTWH(0, 0, s, s), kind);
        _special(canvas, s, body, c, special);
        _symbol(canvas, s, kind);
        return;
      }
    }

    final fill = Paint()..color = colors[kind]!;
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
    _symbol(canvas, s, kind);
  }

  static final _symbolFill = Paint()..color = const Color(0xFFFFFFFF);

  /// Colour-blind mode: a distinct white glyph in the corner of each kind.
  static void _symbol(Canvas canvas, double s, PieceKind kind) {
    if (!SettingsMirror.colorblind) return;
    final r = s * 0.13;
    final c = Offset(s * 0.22, s * 0.22);
    final path = Path();
    switch (kind) {
      case PieceKind.salmon:
        path.addOval(Rect.fromCircle(center: c, radius: r));
      case PieceKind.maguro:
        path.addRect(Rect.fromCircle(center: c, radius: r * 0.9));
      case PieceKind.tamago:
        path
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r, c.dy + r * 0.8)
          ..lineTo(c.dx - r, c.dy + r * 0.8)
          ..close();
      case PieceKind.ikura:
        path
          ..moveTo(c.dx, c.dy - r * 1.1)
          ..lineTo(c.dx + r * 1.1, c.dy)
          ..lineTo(c.dx, c.dy + r * 1.1)
          ..lineTo(c.dx - r * 1.1, c.dy)
          ..close();
      case PieceKind.ebi:
        for (var i = 0; i < 10; i++) {
          final a = -math.pi / 2 + i * math.pi / 5;
          final rr = i.isEven ? r * 1.15 : r * 0.5;
          final pt = c + Offset(math.cos(a), math.sin(a)) * rr;
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        path.close();
      case PieceKind.kappa:
        final t = r * 0.38;
        path
          ..addRect(Rect.fromCenter(center: c, width: r * 2, height: t * 2))
          ..addRect(Rect.fromCenter(center: c, width: t * 2, height: r * 2));
      case PieceKind.unagi:
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          final pt = c + Offset(math.cos(a), math.sin(a)) * (r * 1.1);
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        path.close();
      case PieceKind.hotate:
        path
          ..moveTo(c.dx - r, c.dy + r * 0.7)
          ..arcTo(
              Rect.fromCircle(center: Offset(c.dx, c.dy + r * 0.7), radius: r),
              math.pi,
              math.pi,
              false)
          ..close();
      case PieceKind.ika:
        for (var i = 0; i < 5; i++) {
          final a = -math.pi / 2 + i * 2 * math.pi / 5;
          final pt = c + Offset(math.cos(a), math.sin(a)) * (r * 1.15);
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        path.close();
      case PieceKind.tako:
        final t = r * 0.34;
        path
          ..addPolygon([
            c + Offset(-r, -r + t),
            c + Offset(-r + t, -r),
            c + Offset(r, r - t),
            c + Offset(r - t, r),
          ], true)
          ..addPolygon([
            c + Offset(r, -r + t),
            c + Offset(r - t, -r),
            c + Offset(-r, r - t),
            c + Offset(-r + t, r),
          ], true);
    }
    canvas.drawPath(path, _symbolFill);
    canvas.drawPath(path, _outline);
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
