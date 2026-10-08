import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

import '../gen/assets.gen.dart';

/// Obstacle sprites under assets/ui/obstacles, decoded once for the canvas.
///
/// Until [load] finishes (and in tests that never call it) [ready] is false
/// and callers fall back to the hand-drawn shapes.
enum ObstacleSprite { bag, bomb, fire, gravity, ice, key, mat, nori, portal }

abstract final class ObstacleArt {
  static final _files = {
    ObstacleSprite.bag: Assets.ui.obstacles.bag,
    ObstacleSprite.bomb: Assets.ui.obstacles.bomb,
    ObstacleSprite.fire: Assets.ui.obstacles.fire,
    ObstacleSprite.gravity: Assets.ui.obstacles.gravity,
    ObstacleSprite.ice: Assets.ui.obstacles.ice,
    ObstacleSprite.key: Assets.ui.obstacles.key,
    ObstacleSprite.mat: Assets.ui.obstacles.mat,
    ObstacleSprite.nori: Assets.ui.obstacles.nori,
    ObstacleSprite.portal: Assets.ui.obstacles.portal,
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
  /// about the centre.
  static void draw(Canvas canvas, ObstacleSprite sprite, Rect dst,
      {double alpha = 1, double rot = 0}) {
    final img = _img[sprite]!;
    final src =
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    _paint.color = Color.fromRGBO(255, 255, 255, alpha);
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
