import 'piece.dart';
import 'pos.dart';

enum GameStatus { playing, won, lost }

/// Immutable copy of a piece at the moment a step was produced, so the view
/// never reads core state that has already moved on.
class PieceSnapshot {
  const PieceSnapshot(this.id, this.kind, this.special,
      {this.ice = 0,
      this.ingredient = false,
      this.burning = false,
      this.timer = 0});
  PieceSnapshot.of(Piece p)
      : this(p.id, p.kind, p.special,
            ice: p.ice,
            ingredient: p.ingredient,
            burning: p.burning,
            timer: p.timer);

  final int timer;
  final int ice;
  final bool burning;
  final bool ingredient;
  final int id;
  final PieceKind? kind;
  final SpecialType? special;
}

/// Output of the resolver. The view plays these in order; core state is
/// already final by the time the first one is animated.
sealed class BoardStep {
  const BoardStep();
}

final class SwapStep extends BoardStep {
  const SwapStep(this.a, this.b);
  final Pos a;
  final Pos b;
}

final class InvalidSwapStep extends BoardStep {
  const InvalidSwapStep(this.a, this.b);
  final Pos a;
  final Pos b;
}

final class SpecialActivateStep extends BoardStep {
  const SpecialActivateStep(this.type, this.origin, this.affected,
      {this.comboWith});
  final SpecialType type;
  final Pos origin;
  final Set<Pos> affected;

  /// Set when two specials were swapped into each other.
  final SpecialType? comboWith;
}

final class TransformStep extends BoardStep {
  const TransformStep(this.changes);

  /// pieceId -> new special (Omakase + Knife/Wasabi/Fish).
  final Map<int, SpecialType> changes;
}

class ClearedPiece {
  const ClearedPiece(this.pieceId, this.pos);
  final int pieceId;
  final Pos pos;
}

class SpawnedPiece {
  const SpawnedPiece(this.piece, this.pos);
  final PieceSnapshot piece;
  final Pos pos;
}

final class ClearStep extends BoardStep {
  const ClearStep(this.cleared, this.created, this.scoreGained, this.cascade);
  final List<ClearedPiece> cleared;
  final List<SpawnedPiece> created;
  final int scoreGained;

  /// 1 for the player's own match, 2+ for cascades (score multiplier).
  final int cascade;
}

class FallMove {
  const FallMove(this.pieceId, this.from, this.to);
  final int pieceId;
  final Pos from;
  final Pos to;
}

final class FallStep extends BoardStep {
  const FallStep(this.moves);
  final List<FallMove> moves;
}

class RefillPiece {
  const RefillPiece(this.piece, this.to, this.start);
  final PieceSnapshot piece;
  final Pos to;

  /// Virtual cell beyond the board edge where the piece starts falling.
  final Pos start;
}

final class RefillStep extends BoardStep {
  const RefillStep(this.pieces);
  final List<RefillPiece> pieces;
}

/// Nori layers left on the cells a clear just hit.
final class NoriStep extends BoardStep {
  const NoriStep(this.layers);

  /// cell -> layers remaining (0 = sheet gone).
  final Map<Pos, int> layers;
}

class IceHit {
  const IceHit(this.pieceId, this.pos, this.layers);
  final int pieceId;
  final Pos pos;

  /// Layers left after the hit (0 = the piece is free).
  final int layers;
}

/// Ice cracked by a clear or a special blast.
final class IceStep extends BoardStep {
  const IceStep(this.hits);
  final List<IceHit> hits;
}

class BagHit {
  const BagHit(this.pos, this.layers, {this.mat = false});
  final Pos pos;

  /// True when the cracked blocker is a bamboo mat rather than a rice bag.
  final bool mat;

  /// Layers left after the hit (0 = the bag is gone and the cell opens up).
  final int layers;
}

/// Rice bags cracked by a clear next to them.
final class BagStep extends BoardStep {
  const BagStep(this.hits);
  final List<BagHit> hits;
}

/// Ingredients that reached the bottom row and left for the kitchen.
final class DeliverStep extends BoardStep {
  const DeliverStep(this.delivered);
  final List<ClearedPiece> delivered;
}

/// A bamboo mat growing onto [pos], swallowing the piece [pieceId] there.
final class MatSpreadStep extends BoardStep {
  const MatSpreadStep(this.pos, this.pieceId);
  final Pos pos;
  final int pieceId;
}

/// Fire jumping onto the piece [pieceId] at [pos].
final class IgniteStep extends BoardStep {
  const IgniteStep(this.pos, this.pieceId);
  final Pos pos;
  final int pieceId;
}

class CatHit {
  const CatHit(this.catId, this.pos, this.hp);
  final int catId;
  final Pos pos;

  /// Hit points left (0 = the cat bolts).
  final int hp;
}

/// Cats startled by a clear on or next to them.
final class CatHitStep extends BoardStep {
  const CatHitStep(this.hits);
  final List<CatHit> hits;
}

/// A cat padding over to [to]; the piece there is eaten by the ClearStep that
/// follows.
final class CatMoveStep extends BoardStep {
  const CatMoveStep(this.catId, this.from, this.to);
  final int catId;
  final Pos from;
  final Pos to;
}

/// A key lock opening: [cells] can be swapped from now on.
final class UnlockStep extends BoardStep {
  const UnlockStep(this.cells, this.kind);
  final List<Pos> cells;
  final PieceKind kind;
}

/// Bomb countdowns ticking down; bombs that hit 0 explode.
final class BombStep extends BoardStep {
  const BombStep(this.ticks, this.exploded);

  /// pieceId -> turns left (0 = exploding).
  final Map<int, int> ticks;
  final List<ClearedPiece> exploded;
}

/// A conveyor row sliding one cell; the end piece wraps to the far side.
final class ConveyorStep extends BoardStep {
  const ConveyorStep(this.moves);
  final List<FallMove> moves;
}

final class ShuffleStep extends BoardStep {
  const ShuffleStep(this.positions);

  /// pieceId -> new position.
  final Map<int, Pos> positions;
}

final class TurnEndStep extends BoardStep {
  const TurnEndStep(
      {required this.movesLeft, required this.score, required this.status});
  final int movesLeft;
  final int score;
  final GameStatus status;
}
