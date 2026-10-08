import 'package:flutter/material.dart';

import '../gen/assets.gen.dart';

export 'ui_icons.dart';
export 'ui_widgets.dart';

/// Sprites under assets/ui/.
abstract final class UiArt {
  static final panel = Assets.ui.panel.provider();
  static final heart = Assets.ui.heart.provider();
  static final buttonRound = Assets.ui.buttonRound.provider();
  static final star = Assets.ui.star.provider();
  static final coin = Assets.ui.coin.provider();
  static final gift = Assets.ui.gift.provider();
  static final heartBroken = Assets.ui.heartBroken.provider();
  static final check = Assets.ui.check.provider();

  /// Obstacle icon by id; the ids are the ones the game data uses.
  static AssetGenImage obstacle(String id) => switch (id) {
        'bag' => Assets.ui.obstacles.bag,
        'bomb' => Assets.ui.obstacles.bomb,
        'cat' => Assets.ui.obstacles.cat,
        'conveyor' => Assets.ui.obstacles.conveyor,
        'deliver' => Assets.ui.obstacles.deliver,
        'fire' => Assets.ui.obstacles.fire,
        'gravity' => Assets.ui.obstacles.gravity,
        'ice' => Assets.ui.obstacles.ice,
        'key' => Assets.ui.obstacles.key,
        'mat' => Assets.ui.obstacles.mat,
        'nori' => Assets.ui.obstacles.nori,
        'portal' => Assets.ui.obstacles.portal,
        _ => throw ArgumentError.value(id, 'id', 'no obstacle icon'),
      };

  /// Backdrop of a restaurant's levels; the shared one for an unknown id.
  static AssetGenImage levelBackground(String? id) => switch (id) {
        'tsukiji' => Assets.backgrounds.levelTsukiji,
        'osaka' => Assets.backgrounds.levelOsaka,
        'kyoto' => Assets.backgrounds.levelKyoto,
        'hokkaido' => Assets.backgrounds.levelHokkaido,
        'fukuoka' => Assets.backgrounds.levelFukuoka,
        'okinawa' => Assets.backgrounds.levelOkinawa,
        'omakase' => Assets.backgrounds.levelOmakase,
        'nagoya' => Assets.backgrounds.levelNagoya,
        'hiroshima' => Assets.backgrounds.levelHiroshima,
        'kanazawa' => Assets.backgrounds.levelKanazawa,
        'sendai' => Assets.backgrounds.levelSendai,
        'kobe' => Assets.backgrounds.levelKobe,
        'nara' => Assets.backgrounds.levelNara,
        'ginza' => Assets.backgrounds.levelGinza,
        _ => Assets.backgrounds.bg,
      };

  /// Shop icon by id; the ids are the ones the game data uses.
  static AssetGenImage shop(String id) => switch (id) {
        'tsukiji' => Assets.ui.shops.tsukiji,
        'osaka' => Assets.ui.shops.osaka,
        'kyoto' => Assets.ui.shops.kyoto,
        'hokkaido' => Assets.ui.shops.hokkaido,
        'fukuoka' => Assets.ui.shops.fukuoka,
        'okinawa' => Assets.ui.shops.okinawa,
        'omakase' => Assets.ui.shops.omakase,
        'nagoya' => Assets.ui.shops.nagoya,
        'hiroshima' => Assets.ui.shops.hiroshima,
        'kanazawa' => Assets.ui.shops.kanazawa,
        'sendai' => Assets.ui.shops.sendai,
        'kobe' => Assets.ui.shops.kobe,
        'nara' => Assets.ui.shops.nara,
        'ginza' => Assets.ui.shops.ginza,
        _ => throw ArgumentError.value(id, 'id', 'no shop icon'),
      };

  /// Furniture icon by id; the ids are the ones the game data uses.
  static AssetGenImage furniture(String id) => switch (id) {
        'lantern' => Assets.sprites.furniture.lantern,
        'stool' => Assets.sprites.furniture.stool,
        'noren' => Assets.sprites.furniture.noren,
        'sign' => Assets.sprites.furniture.sign,
        'plant' => Assets.sprites.furniture.plant,
        'luckycat' => Assets.sprites.furniture.luckycat,
        'aquarium' => Assets.sprites.furniture.aquarium,
        'conveyor' => Assets.sprites.furniture.conveyor,
        'kadomatsu' => Assets.sprites.furniture.kadomatsu,
        'taiko' => Assets.sprites.furniture.taiko,
        'sake' => Assets.sprites.furniture.sake,
        'trophy' => Assets.sprites.furniture.trophy,
        _ => throw ArgumentError.value(id, 'id', 'no furniture icon'),
      };

  /// A square sprite decoded near its display size (3x, like [BoosterIcon]):
  /// the sources are 192-292px but icons are drawn at 16-44.
  static Widget sized(ImageProvider image, double size) => Image(
        image: ResizeImage(image, width: (size * 3).round()),
        width: size,
        height: size,
      );

  static const ink = Color(0xFF4A2E1B);
  static const paper = Color(0xFFFBF1DC);

  /// Wooden board with wave corners; stretches without distorting the frame.
  static BoxDecoration panelDecoration() => BoxDecoration(
        image: DecorationImage(
          image: panel,
          fit: BoxFit.fill,
          // The sprite is 890px wide: `scale` shrinks it to logical size and
          // centerSlice is expressed in those logical units.
          scale: 3,
          centerSlice: const Rect.fromLTRB(55, 42.5, 241.5, 95),
        ),
      );

  /// Wooden plank sprite stretched as a nine-patch so the rounded ends stay
  /// undistorted.
  static BoxDecoration plankSpriteDecoration() => BoxDecoration(
        image: DecorationImage(
          image: Assets.ui.plank.provider(),
          fit: BoxFit.fill,
          // 829x230 sprite: scale shrinks it to ~138x38 logical units and
          // centerSlice is expressed in those units.
          scale: 6,
          centerSlice: const Rect.fromLTRB(16, 16, 122, 22),
        ),
      );

  /// Flat cream chip with a thin ink outline. Replaces the old wood-grain
  /// plank so only the big panels carry the wood-and-wave frame.
  static BoxDecoration plankDecoration() => BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ink.withValues(alpha: 0.55), width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      );
}

extension SizedAsset on AssetGenImage {
  /// Square image of [size] decoded near that size; see [UiArt.sized].
  Image sized(double size) => image(
        width: size,
        height: size,
        cacheWidth: (size * 3).round(),
      );
}
