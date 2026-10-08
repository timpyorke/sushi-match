import 'package:flutter/material.dart';

import '../core/level.dart';
import '../game/board_component.dart';

/// The order bubble just above the board: the customer sits close to it, and
/// the leftover height is split above the pair and under the board.
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
    final spare = avail - boardH;
    final between = spare.clamp(0.0, 6.0);
    final gap = (spare - between) / 2;
    positionChild(_orderId, Offset(0, gap));
    positionChild(_boardId, Offset(0, gap + orderSize.height + between));
  }

  @override
  bool shouldRelayout(_StageDelegate old) => old.level != level;
}
