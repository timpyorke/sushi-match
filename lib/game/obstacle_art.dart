import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

import '../gen/assets.gen.dart';

/// Obstacle sprites under assets/sprites/tiles, decoded once for the canvas.
///
/// Until [load] finishes (and in tests that never call it) [ready] is false
/// and callers fall back to the hand-drawn shapes.
enum ObstacleSprite {
  bag1,
  bag2,
  bag3,
  bomb,
  fire1,
  fire2,
  fire3,
  fire4,
  gravity,
  ice1,
  ice2,
  ice3,
  lock,
  mat,
  nori1,
  nori2,
  nori3,
  portalIn,
  portalOut,
  select,
}

abstract final class ObstacleArt {
  static final _files = {
    ObstacleSprite.bag1: Assets.sprites.tiles.bag1,
    ObstacleSprite.bag2: Assets.sprites.tiles.bag2,
    ObstacleSprite.bag3: Assets.sprites.tiles.bag3,
    ObstacleSprite.bomb: Assets.sprites.tiles.bomb,
    ObstacleSprite.fire1: Assets.sprites.tiles.fire1,
    ObstacleSprite.fire2: Assets.sprites.tiles.fire2,
    ObstacleSprite.fire3:
        const AssetGenImage('assets/sprites/tiles/fire_3.webp'),
    ObstacleSprite.fire4:
        const AssetGenImage('assets/sprites/tiles/fire_4.webp'),
    ObstacleSprite.gravity: Assets.sprites.tiles.gravityArrow,
    ObstacleSprite.ice1: Assets.sprites.tiles.ice1,
    ObstacleSprite.ice2: Assets.sprites.tiles.ice2,
    ObstacleSprite.ice3: Assets.sprites.tiles.ice3,
    ObstacleSprite.lock: Assets.sprites.tiles.lock,
    ObstacleSprite.mat: Assets.sprites.tiles.mat,
    ObstacleSprite.nori1: Assets.sprites.tiles.nori1,
    ObstacleSprite.nori2: Assets.sprites.tiles.nori2,
    ObstacleSprite.nori3: Assets.sprites.tiles.nori3,
    ObstacleSprite.portalIn: Assets.sprites.tiles.portalIn,
    ObstacleSprite.portalOut: Assets.sprites.tiles.portalOut,
    ObstacleSprite.select: Assets.sprites.tiles.select,
  };

  static final _img = <ObstacleSprite, Image>{};

  static bool get ready => _img.length == _files.length;

  static Future<void> load() async {
    for (final e in _files.entries) {
      if (_img.containsKey(e.key)) continue;
      final data = await rootBundle.load(e.value.path);
      final codec = await instantiateImageCodec(data.buffer.asUint8List());
      _img[e.key] = (await codec.getNextFrame()).image;
    }
  }

  static final _paint = Paint()..filterQuality = FilterQuality.medium;

  /// Draws [sprite] fitted inside [dst]; [alpha] 0..1, [rot] in radians
  /// about the centre, [tint] multiplied over the sprite.
  static void draw(Canvas canvas, ObstacleSprite sprite, Rect dst,
      {double alpha = 1, double rot = 0, Color? tint}) {
    final img = _img[sprite]!;
    final src =
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    _paint
      ..color = Color.fromRGBO(255, 255, 255, alpha)
      // Grey sprites (lock, portals) take a colour by multiplying.
      ..colorFilter =
          tint == null ? null : ColorFilter.mode(tint, BlendMode.modulate);
    if (rot == 0) {
      canvas.drawImageRect(img, src, dst, _paint);
      return;
    }
    canvas.save();
    canvas.translate(dst.center.dx, dst.center.dy);
    canvas.rotate(rot);
    canvas.drawImageRect(
        img,
        src,
        Rect.fromCenter(
            center: Offset.zero, width: dst.width, height: dst.height),
        _paint);
    canvas.restore();
  }
}
