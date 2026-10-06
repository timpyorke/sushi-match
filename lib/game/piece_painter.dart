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
  };

  static final _eye = Paint()..color = const Color(0xFF3B2A20);
  static final _white = Paint()..color = const Color(0xFFFFFFFF);
  static final _nori = Paint()..color = const Color(0xFF1F2A1E);
  static final _outline = Paint()
    ..color = const Color(0xFF3B2A20)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  static const _sheetAsset = 'assets/sushi/sushi.png';
  static Image? _sheet;

  /// Loads the sprite sheet (3 columns x 2 rows, in [PieceKind] order).
  /// Until it finishes, pieces fall back to the vector art.
  static Future<void> loadSprites() async {
    if (_sheet != null) return;
    final data = await rootBundle.load(_sheetAsset);
    final codec = await instantiateImageCodec(data.buffer.asUint8List());
    _sheet = (await codec.getNextFrame()).image;
  }

  static void _sprite(Canvas canvas, Rect dst, PieceKind kind) {
    final sheet = _sheet!;
    final cw = sheet.width / 3, ch = sheet.height / 2;
    final i = kind.index;
    final src = Rect.fromLTWH((i % 3) * cw, (i ~/ 3) * ch, cw, ch);
    canvas.drawImageRect(
        sheet, src, dst, Paint()..filterQuality = FilterQuality.medium);
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
      _plate(canvas, c, s);
      return;
    }

    if (_sheet != null) {
      _sprite(canvas, Rect.fromLTWH(0, 0, s, s), kind);
      _special(canvas, s, body, c, special);
      return;
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
