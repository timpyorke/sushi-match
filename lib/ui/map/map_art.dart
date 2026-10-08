import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../../gen/assets.gen.dart';

/// Decoded level-map sprites: the shared ones under their file name (`plate`,
/// `sea_a`…) and a region's own under `<region>/<file>` (`kyoto/land_a`…).
/// Anything missing is simply `null`, so the painter falls back to shapes.
class MapArt {
  MapArt._(this._images);
  final Map<String, Image> _images;

  Image? operator [](String key) => _images[key];

  /// Region sprite, e.g. `region('kyoto', 'city')`.
  Image? region(String id, String file) => _images['$id/$file'];

  static Future<MapArt>? _loading;

  /// Decodes everything once; later calls share the same future.
  static Future<MapArt> load() => _loading ??= _load();

  static Future<MapArt> _load() async {
    final images = <String, Image>{};
    Future<void> add(String key, AssetGenImage asset, int width) async {
      try {
        final data = await rootBundle.load(asset.path);
        final codec = await instantiateImageCodec(data.buffer.asUint8List(),
            targetWidth: width);
        images[key] = (await codec.getNextFrame()).image;
      } catch (_) {
        // Leave it out: the painter draws its fallback shape.
      }
    }

    final c = Assets.sprites.map.common;
    await Future.wait([
      for (final (k, a) in <(String, AssetGenImage)>[
        ('banner', c.banner),
        ('cliff', c.cliff),
        ('cliff_l', c.cliffL),
        ('cliff_u', c.cliffU),
        ('cloud_lock', c.cloudLock),
        ('flag_boss', c.flagBoss),
        ('marker', c.marker),
        ('plate', c.plate),
        ('plate_current', c.plateCurrent),
        ('plate_locked', c.plateLocked),
        ('route_done', c.routeDone),
        ('route_dot', c.routeDot),
        ('sea_a', c.seaA),
        ('sea_b', c.seaB),
        ('sea_c', c.seaC),
        ('sea_d', c.seaD),
        ('star_dim', c.starDim),
        ('star_lit', c.starLit),
        ('wave_crest', c.waveCrest),
      ])
        add(k, a, k == 'banner' ? 512 : 128),
    ]);

    final m = Assets.sprites.map;
    final regions = <String, List<AssetGenImage>>{
      'tsukiji': _set(m.tsukiji),
      'osaka': _set(m.osaka),
      'kyoto': _set(m.kyoto),
      'hokkaido': _set(m.hokkaido),
      'fukuoka': _set(m.fukuoka),
      'okinawa': _set(m.okinawa),
      'omakase': _set(m.omakase),
      'nagoya': _set(m.nagoya),
      'hiroshima': _set(m.hiroshima),
      'kanazawa': _set(m.kanazawa),
      'sendai': _set(m.sendai),
      'kobe': _set(m.kobe),
      'nara': _set(m.nara),
      'ginza': _set(m.ginza),
    };
    const files = [
      'land_a', 'land_b', 'land_c', 'land_d', //
      'mountain', 'forest', 'city', 'special', 'landmark'
    ];
    await Future.wait([
      for (final e in regions.entries)
        for (var i = 0; i < files.length; i++)
          add('${e.key}/${files[i]}', e.value[i], 128),
    ]);
    return MapArt._(images);
  }

  // Every region class has the same getters but no common type.
  static List<AssetGenImage> _set(dynamic r) => [
        r.landA,
        r.landB,
        r.landC,
        r.landD,
        r.mountain,
        r.forest,
        r.city,
        r.special,
        r.landmark,
      ];
}

/// Wraps an already decoded [Image] as an [ImageProvider].
class DecodedImage extends ImageProvider<DecodedImage> {
  const DecodedImage(this.image);
  final Image image;

  @override
  Future<DecodedImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
          DecodedImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(SynchronousFuture(ImageInfo(image: image)));

  @override
  bool operator ==(Object other) =>
      other is DecodedImage && other.image == image;

  @override
  int get hashCode => image.hashCode;
}
