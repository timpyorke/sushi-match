import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

/// Board tile sprites (assets/sprites/tiles/*.png, each pre-cropped to its tile).
///
/// cell_light/cell_dark: checkerboard cells. frame_strip: wave band + outer
/// rim of the board frame. belt_straight/belt_corner/belt_cap/arrow: conveyor.
///
/// Until [load] finishes (and in tests that never call it) [ready] is false
/// and the board falls back to flat colours.
enum MapTile { straight, corner, cap }

abstract final class TileArt {
  static const _names = [
    'cell_light',
    'cell_dark',
    'frame_strip',
    'belt_straight',
    'belt_corner',
    'belt_cap',
    'arrow',
  ];

  static final _img = <String, Image>{};

  static bool get ready => _img.length == _names.length;

  static Future<void> load() async {
    for (final n in _names) {
      _img[n] ??= await _decode('assets/sprites/tiles/$n.png');
    }
  }

  static Future<Image> _decode(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  static final _paint = Paint()..filterQuality = FilterQuality.medium;

  static void _draw(Canvas canvas, String name, Rect dst,
      {bool flipX = false}) {
    final img = _img[name]!;
    final src =
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
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
      _draw(canvas, dark ? 'cell_dark' : 'cell_light', dst);

  /// Straight belt segment.
  static void belt(Canvas canvas, Rect dst) =>
      _draw(canvas, 'belt_straight', dst);

  /// Rounded end of a belt; [leftEnd] mirrors it for the left side.
  static void beltCap(Canvas canvas, Rect dst, {required bool leftEnd}) =>
      _draw(canvas, 'belt_cap', dst, flipX: leftEnd);

  /// One belt-sheet tile for the level map, centred on [centre] in a
  /// [width]×[height] box. [rot] is applied first, then the optional flips.
  static void mapTile(
      Canvas canvas, MapTile kind, Offset centre, double width, double height,
      {double rot = 0, bool flipX = false, bool flipY = false}) {
    final img = _img[switch (kind) {
      MapTile.straight => 'belt_straight',
      MapTile.corner => 'belt_corner',
      MapTile.cap => 'belt_cap',
    }]!;
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(rot);
    canvas.scale(flipX ? -1 : 1, flipY ? -1 : 1);
    canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromCenter(center: Offset.zero, width: width, height: height),
        _paint);
    canvas.restore();
  }

  /// Direction arrow; [dir] is +1 for right, -1 for left.
  static void arrow(Canvas canvas, Rect dst, int dir) =>
      _draw(canvas, 'arrow', dst, flipX: dir < 0);

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
    final strip = _img['frame_strip']!;
    for (final (poly, centre, angle, length) in bars) {
      canvas.save();
      canvas.clipPath(Path()..addPolygon(poly, true));
      canvas.translate(centre.dx, centre.dy);
      canvas.rotate(angle);
      canvas.drawImageRect(
          strip,
          Rect.fromLTWH(0, 0, strip.width.toDouble(), strip.height.toDouble()),
          Rect.fromCenter(center: Offset.zero, width: length, height: t),
          _paint);
      canvas.restore();
    }
  }
}
