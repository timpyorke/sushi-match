import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

/// Board tile sprites cut from the two 2×2 tile sheets.
///
/// tileset02: light wood cell, dark wood cell, frame strip + corner (only
/// the strip's wave band and outer rim are used, as the board frame).
/// tileset01: straight belt, corner belt, arrow, belt end cap.
///
/// Until [load] finishes (and in tests that never call it) [ready] is false
/// and the board falls back to flat colours.
abstract final class TileArt {
  static const _cellsAsset = 'assets/images/tileset02.png';
  static const _beltAsset = 'assets/images/tileset01.png';

  static Image? _cells;
  static Image? _belt;

  static bool get ready => _cells != null && _belt != null;

  // Source rects in the 1254×1254 sheets (tile + its dark outline).
  static const _topLeft = Rect.fromLTWH(46, 46, 566, 560);
  static const _topRight = Rect.fromLTWH(646, 46, 566, 560);
  static const _bottomRight = Rect.fromLTWH(646, 636, 566, 566);

  /// The orange arrow on the bottom-left tile of tileset01, pointing right.
  static const _arrow = Rect.fromLTWH(104, 748, 444, 264);

  /// Wave band + outer rim of the frame strip (bottom-left tile of tileset02);
  /// the thick wood above it is hidden behind the board.
  static const _frameStrip = Rect.fromLTWH(52, 944, 552, 252);

  static Future<void> load() async {
    _cells ??= await _decode(_cellsAsset);
    _belt ??= await _decode(_beltAsset);
  }

  static Future<Image> _decode(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  static final _paint = Paint()..filterQuality = FilterQuality.medium;

  static void _draw(Canvas canvas, Image img, Rect src, Rect dst,
      {bool flipX = false}) {
    if (!flipX) {
      canvas.drawImageRect(img, src, dst, _paint);
      return;
    }
    canvas.save();
    canvas.translate(dst.center.dx, 0);
    canvas.scale(-1, 1);
    canvas.drawImageRect(img, src,
        Rect.fromLTWH(-dst.width / 2, dst.top, dst.width, dst.height), _paint);
    canvas.restore();
  }

  /// Checkerboard cell: [dark] alternates with the light one.
  static void cell(Canvas canvas, Rect dst, {required bool dark}) =>
      _draw(canvas, _cells!, dark ? _topRight : _topLeft, dst);

  /// Straight belt segment.
  static void belt(Canvas canvas, Rect dst) =>
      _draw(canvas, _belt!, _topLeft, dst);

  /// Rounded end of a belt; [leftEnd] mirrors it for the left side.
  static void beltCap(Canvas canvas, Rect dst, {required bool leftEnd}) =>
      _draw(canvas, _belt!, _bottomRight, dst, flipX: leftEnd);

  /// Direction arrow; [dir] is +1 for right, -1 for left.
  static void arrow(Canvas canvas, Rect dst, int dir) =>
      _draw(canvas, _belt!, _arrow, dst, flipX: dir < 0);

  /// Frame of thickness [t] around [board]. The strip is drawn once per side
  /// and cut at 45° so the band runs round the corners.
  static void frame(Canvas canvas, Rect board, double t) {
    final b = board;
    final bars = <(List<Offset>, Offset, double, double)>[
      // (mitre polygon, centre, rotation, length)
      (
        [
          Offset(b.left - t, b.bottom + t),
          Offset(b.right + t, b.bottom + t),
          Offset(b.right, b.bottom),
          Offset(b.left, b.bottom),
        ],
        Offset(b.center.dx, b.bottom + t / 2),
        0,
        b.width + 2 * t,
      ),
      (
        [
          Offset(b.left - t, b.top - t),
          Offset(b.right + t, b.top - t),
          Offset(b.right, b.top),
          Offset(b.left, b.top),
        ],
        Offset(b.center.dx, b.top - t / 2),
        3.141592653589793,
        b.width + 2 * t,
      ),
      (
        [
          Offset(b.right + t, b.top - t),
          Offset(b.right + t, b.bottom + t),
          Offset(b.right, b.bottom),
          Offset(b.right, b.top),
        ],
        Offset(b.right + t / 2, b.center.dy),
        -1.5707963267948966,
        b.height + 2 * t,
      ),
      (
        [
          Offset(b.left - t, b.top - t),
          Offset(b.left - t, b.bottom + t),
          Offset(b.left, b.bottom),
          Offset(b.left, b.top),
        ],
        Offset(b.left - t / 2, b.center.dy),
        1.5707963267948966,
        b.height + 2 * t,
      ),
    ];
    for (final (poly, centre, angle, length) in bars) {
      canvas.save();
      canvas.clipPath(Path()..addPolygon(poly, true));
      canvas.translate(centre.dx, centre.dy);
      canvas.rotate(angle);
      canvas.drawImageRect(
          _cells!,
          _frameStrip,
          Rect.fromCenter(center: Offset.zero, width: length, height: t),
          _paint);
      canvas.restore();
    }
  }
}
