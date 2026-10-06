import 'dart:ui';

import 'package:flame/components.dart';

import '../core/piece.dart';
import 'piece_painter.dart';

class PieceComponent extends PositionComponent {
  PieceComponent({
    required this.pieceId,
    required this.kind,
    required this.special,
    required double cellSize,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2.all(cellSize),
          anchor: Anchor.center,
        );

  final int pieceId;
  final PieceKind? kind;
  SpecialType? special;

  @override
  void render(Canvas canvas) => PiecePainter.paint(canvas, size.x, kind, special);
}
