import '../core/piece.dart';
import 'restaurant.dart';

/// How the shop groups furniture. [dining] pieces also add a display slot
/// for sushi (see [Restaurant.slotCount]).
enum FurnitureCategory { storefront, dining, charm, ambience }

/// A piece of furniture for the player's restaurant, bought once with stars.
/// Its [appeal] makes customers come sooner and pay more for the sushi on
/// display (see [RestaurantState.priceBoost] and [RestaurantState.visitEvery]).
class FurnitureDef {
  const FurnitureDef(this.id, this.category, this.cost, this.appeal);
  final String id;
  final FurnitureCategory category;
  final int cost;
  final int appeal;

  String get nameKey => 'furn_$id';
}

/// One region of the level map: a block of levels with its own name, map
/// band and music. Regions open by clearing levels, not by buying.
class ShopDef {
  const ShopDef(this.id, this.firstLevel, this.lastLevel);
  final String id;
  final int firstLevel;
  final int lastLevel;

  String get nameKey => 'shop_$id';
}

/// Map regions, the furniture catalogue and the till's constants.
///
/// Pacing (a mid-skill bot averages ~2.2 stars a level, ~450 over 205
/// levels): the furniture costs 400 stars in all, so a player furnishes the
/// whole restaurant near the end of the map, sooner by replaying for 3 stars.
abstract final class Restaurant {
  static const shops = [
    ShopDef('tsukiji', 1, 15),
    ShopDef('osaka', 16, 30),
    ShopDef('kyoto', 31, 45),
    ShopDef('hokkaido', 46, 60),
    ShopDef('fukuoka', 61, 75),
    ShopDef('okinawa', 76, 90),
    ShopDef('omakase', 91, 100),
    ShopDef('nagoya', 101, 115),
    ShopDef('hiroshima', 116, 130),
    ShopDef('kanazawa', 131, 145),
    ShopDef('sendai', 146, 160),
    ShopDef('kobe', 161, 175),
    ShopDef('nara', 176, 190),
    ShopDef('ginza', 191, 205),
  ];

  /// Cheapest first; the scene places each by id.
  static const furniture = [
    FurnitureDef('lantern', FurnitureCategory.ambience, 2, 2),
    FurnitureDef('stool', FurnitureCategory.dining, 4, 2),
    FurnitureDef('noren', FurnitureCategory.storefront, 7, 3),
    FurnitureDef('sign', FurnitureCategory.storefront, 10, 3),
    FurnitureDef('plant', FurnitureCategory.charm, 15, 4),
    FurnitureDef('luckycat', FurnitureCategory.charm, 20, 4),
    FurnitureDef('aquarium', FurnitureCategory.charm, 28, 5),
    FurnitureDef('conveyor', FurnitureCategory.dining, 38, 5),
    FurnitureDef('kadomatsu', FurnitureCategory.storefront, 50, 6),
    FurnitureDef('taiko', FurnitureCategory.ambience, 62, 6),
    FurnitureDef('sake', FurnitureCategory.dining, 74, 8),
    FurnitureDef('trophy', FurnitureCategory.ambience, 90, 10),
  ];

  static Iterable<FurnitureDef> inCategory(FurnitureCategory c) =>
      furniture.where((f) => f.category == c);

  /// Coins one customer pays for a piece of sushi before the appeal bonus.
  static const basePrice = {
    PieceKind.kappa: 3,
    PieceKind.tamago: 4,
    PieceKind.ika: 5,
    PieceKind.tako: 5,
    PieceKind.salmon: 6,
    PieceKind.ebi: 7,
    PieceKind.maguro: 8,
    PieceKind.unagi: 9,
    PieceKind.hotate: 9,
    PieceKind.ikura: 10,
  };

  /// Display slots at the start, one more for each dining furniture bought.
  static const baseSlots = 3;
  static final maxSlots =
      baseSlots + inCategory(FurnitureCategory.dining).length;

  /// A customer comes this often with no furniture, and this often at best.
  static const slowestVisit = 60;
  static const fastestVisit = 25;

  /// Sushi earned by winning a level: one more than the stars it scored.
  static int sushiReward(int stars) => stars + 1;

  /// The sushi a won level pays out: its own palette, rotated by level
  /// number so neighbouring levels favour different kinds.
  static List<PieceKind> rewardFor(
      int level, int stars, List<PieceKind> palette) {
    if (palette.isEmpty) return const [];
    return [
      for (var i = 0; i < sushiReward(stars); i++)
        palette[(level + i) % palette.length],
    ];
  }

  /// Number of levels in the game: the end of the last region. To add
  /// levels, extend the last shop or append a new one (see
  /// docs/adding-levels.md).
  static int get totalLevels => shops.last.lastLevel;

  static ShopDef? shopOfLevel(int level) {
    for (final s in shops) {
      if (level >= s.firstLevel && level <= s.lastLevel) return s;
    }
    return null;
  }
}
