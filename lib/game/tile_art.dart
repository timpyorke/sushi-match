import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

import '../gen/assets.gen.dart';

/// Board tile sprites (each pre-cropped to its tile).
///
/// cell_light/cell_dark: checkerboard cells. belt_straight/belt_corner/
/// belt_cap/arrow: conveyor.
///
/// Until [load] finishes (and in tests that never call it) [ready] is false
/// and the board falls back to flat colours.
enum MapTile { straight, corner, cap }

abstract final class TileArt {
  static final _files = {
    'cell_light': Assets.sprites.tiles.cellLight,
    'cell_dark': Assets.sprites.tiles.cellDark,
    'belt_straight': Assets.sprites.tiles.beltStraight,
    'belt_corner': Assets.sprites.tiles.beltCorner,
    'belt_cap': Assets.sprites.tiles.beltCap,
    'arrow': Assets.sprites.tiles.arrow,
  };

  static final _img = <String, Image>{};

  static bool get ready => _img.length == _files.length;

  static Future<void> load() async {
    for (final e in _files.entries) {
      _img[e.key] ??= await _decode(e.value.path);
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
}
