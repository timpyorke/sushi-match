enum PieceKind { salmon, maguro, tamago, ikura, ebi, kappa }

enum SpecialType {
  /// Chef Knife from a horizontal 4 — clears the whole row.
  knifeRow,

  /// Chef Knife from a vertical 4 — clears the whole column.
  knifeCol,

  /// Wasabi Bomb from an L/T shape — 3×3 blast.
  wasabi,

  /// Omakase Plate from a straight 5 — colourless, clears one kind.
  omakase,

  /// Soy Fish from a 2×2 square — hits one target cell.
  soyFish;

  bool get isKnife => this == knifeRow || this == knifeCol;
}

class Piece {
  Piece({required this.id, required this.kind, this.special})
      : assert(kind != null || special == SpecialType.omakase);

  /// Stable id so the view can track a piece across steps.
  final int id;

  /// Null only for the Omakase Plate.
  final PieceKind? kind;

  /// Mutable: Omakase + Knife/Wasabi combos upgrade pieces in place.
  SpecialType? special;

  /// Ice layers caging the piece. A frozen piece cannot be swapped or
  /// matched; clears next to it (or special blasts) crack one layer each.
  int ice = 0;

  bool get frozen => ice > 0;

  bool get isSpecial => special != null;
  bool get isOmakase => special == SpecialType.omakase;

  @override
  String toString() =>
      'Piece#$id(${kind?.name ?? '-'}${special != null ? '+${special!.name}' : ''})';
}
