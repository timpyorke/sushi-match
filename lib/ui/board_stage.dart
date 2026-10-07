import 'package:flutter/material.dart';

import '../core/level.dart';
import '../game/board_component.dart';

/// The order bubble above the board, with the leftover height split evenly
/// above the bubble, between it and the board, and under the board, so the
/// customer sits halfway between the HUD and the board.
///
/// [board] gets just the height the board needs at its fitted scale; a board
/// that fills the height leaves no spare room and the bubble sits on top.
class BoardStage extends StatelessWidget {
  const BoardStage({
    super.key,
    required this.level,
    required this.order,
    required this.board,
  });
  final LevelConfig level;
  final Widget order;
  final Widget board;

  @override
  Widget build(BuildContext context) => CustomMultiChildLayout(
        delegate: _StageDelegate(level),
        children: [
          LayoutId(id: _orderId, child: order),
          LayoutId(id: _boardId, child: board),
        ],
      );
}

const _orderId = 'order';
const _boardId = 'board';

class _StageDelegate extends MultiChildLayoutDelegate {
  _StageDelegate(this.level);
  final LevelConfig level;

  @override
  void performLayout(Size size) {
    final orderSize = layoutChild(
        _orderId, BoxConstraints.loose(Size(size.width, size.height)));
    final avail = size.height - orderSize.height;
    final s = BoardComponent.fitScale(
        size.width, avail, level.cols, level.rows, level.gravity);
    final boardH =
        BoardComponent.areaFor(s, level.rows, level.gravity).clamp(0.0, avail);
    layoutChild(_boardId, BoxConstraints.tight(Size(size.width, boardH)));
    final gap = (avail - boardH) / 3;
    positionChild(_orderId, Offset(0, gap));
    positionChild(_boardId, Offset(0, gap + orderSize.height + gap));
  }

  @override
  bool shouldRelayout(_StageDelegate old) => old.level != level;
}
