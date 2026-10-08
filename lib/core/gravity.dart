import 'dart:math';

import 'board.dart';
import 'level.dart';
import 'piece.dart';
import 'pos.dart';
import 'steps.dart';

/// Gravity for one board: drops pieces along [gravity], through void cells
/// and portals, slides them round blocked cells and feeds new ones in from
/// upstream.
///
/// Gravity runs along "lines": columns for up/down, rows for left/right.
/// Cells are indexed upstream (where new pieces enter) to downstream.
class GravitySettler {
  GravitySettler(this.board, this.gravity, this.portals, this.rng,
      {required this.isBlocked, required this.newPiece});

  final Board board;
  final Gravity gravity;
  final List<PortalSpec> portals;
  final Random rng;

  /// Whether [p] holds a rice bag or mat; falling pieces stop above it.
  final bool Function(Pos p) isBlocked;

  /// The next piece fed in from upstream.
  final Piece Function() newPiece;

  int get lineCount => gravity.vertical ? board.cols : board.rows;

  int get lineLength => gravity.vertical ? board.rows : board.cols;

  Pos get _step => Pos(gravity.dr, gravity.dc);

  /// The [k]th cell of [line], counted from upstream.
  Pos lineCell(int line, int k) => switch (gravity) {
        Gravity.down => Pos(k, line),
        Gravity.up => Pos(board.rows - 1 - k, line),
        Gravity.right => Pos(line, k),
        Gravity.left => Pos(line, board.cols - 1 - k),
      };

  /// Drops every piece as far as it goes, refills from upstream and returns
  /// the moves as a [FallStep] and a [RefillStep].
  List<BoardStep> settle() {
    final before = <int, Pos>{
      for (final p in board.positions)
        if (board[p] != null) board[p]!.id: p,
    };
    final fresh = <int, (PieceSnapshot, Pos)>{};
    final segments = _segments();
    final transfers = _linkPortals(segments);
    for (var round = 0; round < 100; round++) {
      for (final seg in segments) {
        _collapse(seg, fresh);
      }
      // Both run every round; either moving a piece needs another round.
      final ported = _runPortals(transfers);
      final slid = _slideIntoSealed(segments);
      if (!ported && !slid) break;
    }
    return _settleSteps(before, fresh);
  }

  /// The runs of open cells along each gravity line, upstream first. A line
  /// splits at rice bags (void cells stay transparent to falling pieces,
  /// bags do not). Only the first segment of a line is fed from upstream;
  /// the others fill by pieces sliding in diagonally.
  List<_Segment> _segments() {
    final segments = <_Segment>[];
    for (var line = 0; line < lineCount; line++) {
      var current = <Pos>[];
      var sealed = false;
      void close() {
        if (current.isNotEmpty) {
          segments.add(_Segment(current, fed: !sealed));
          sealed = true;
        }
        current = <Pos>[];
      }

      for (var k = 0; k < lineLength; k++) {
        final p = lineCell(line, k);
        if (isBlocked(p)) {
          close();
          sealed = true;
        } else if (board.isPlayable(p)) {
          current.add(p);
        }
      }
      close();
    }
    return segments;
  }

  /// Portals: the piece resting at the end of the segment above an entry
  /// reappears at the top of the exit's segment whenever that has room. The
  /// exit segment is fed by the portal instead of from upstream.
  List<(_Segment, _Segment)> _linkPortals(List<_Segment> segments) {
    final step = _step;
    final transfers = <(_Segment, _Segment)>[];
    for (final portal in portals) {
      final into = segments.where((c) => c.cells.last + step == portal.entry);
      final out = segments.where((c) => c.cells.first == portal.exit);
      if (into.isEmpty || out.isEmpty) continue;
      transfers.add((into.first, out.first));
      out.first
        ..fed = false
        ..portalFed = true;
    }
    return transfers;
  }

  /// Packs [seg]'s pieces downstream and, when it is fed from upstream,
  /// fills the gap with new pieces, recording where each one enters in
  /// [fresh].
  void _collapse(_Segment seg, Map<int, (PieceSnapshot, Pos)> fresh) {
    final cells = seg.cells;
    final stack = [
      for (final p in cells)
        if (board[p] != null) board[p]!,
    ];
    for (final p in cells) {
      board[p] = null;
    }
    var w = cells.length - 1;
    for (var i = stack.length - 1; i >= 0; i--, w--) {
      board[cells[w]] = stack[i];
    }
    if (!seg.fed) return;
    final missing = w + 1;
    final first = cells.first;
    final step = _step;
    for (var i = 0; i < missing; i++) {
      final piece = newPiece();
      board[cells[i]] = piece;
      final back = missing - i;
      fresh[piece.id] = (
        PieceSnapshot.of(piece),
        Pos(first.row - step.row * back, first.col - step.col * back),
      );
    }
  }

  /// Moves one piece through each portal whose exit has room.
  bool _runPortals(List<(_Segment, _Segment)> transfers) {
    var moved = false;
    for (final (into, out) in transfers) {
      final from = into.cells.last, to = out.cells.first;
      if (board[from] != null && board[to] == null) {
        board[to] = board[from];
        board[from] = null;
        moved = true;
      }
    }
    return moved;
  }

  /// Sealed segments whose first cell is empty pull a piece in from the
  /// neighbouring line, one cell upstream.
  bool _slideIntoSealed(List<_Segment> segments) {
    final step = _step;
    final perp = Pos(step.col.abs(), step.row.abs());
    var moved = false;
    for (final seg in segments) {
      if (seg.fed || seg.portalFed) continue;
      final top = seg.cells.first;
      if (board[top] != null) continue;
      final up = top - step;
      final donors = [
        for (final d in [perp, Pos(-perp.row, -perp.col)])
          if (board[up + d] != null) up + d,
      ];
      if (donors.isEmpty) continue;
      final from = donors[rng.nextInt(donors.length)];
      board[top] = board[from];
      board[from] = null;
      moved = true;
    }
    return moved;
  }

  /// The falls and refills that took the board from [before] to now.
  List<BoardStep> _settleSteps(
      Map<int, Pos> before, Map<int, (PieceSnapshot, Pos)> fresh) {
    final falls = <FallMove>[];
    final refills = <RefillPiece>[];
    for (final p in board.positions) {
      final piece = board[p];
      if (piece == null) continue;
      final f = fresh[piece.id];
      if (f != null) {
        refills.add(RefillPiece(f.$1, p, f.$2));
      } else if (before[piece.id] != p) {
        falls.add(FallMove(piece.id, before[piece.id]!, p));
      }
    }
    return [
      if (falls.isNotEmpty) FallStep(falls),
      if (refills.isNotEmpty) RefillStep(refills),
    ];
  }
}

/// A run of open cells along one gravity line, upstream first.
class _Segment {
  _Segment(this.cells, {required this.fed});
  final List<Pos> cells;

  /// Whether new pieces enter at the top of this segment.
  bool fed;

  /// Whether a portal feeds this segment.
  bool portalFed = false;
}
