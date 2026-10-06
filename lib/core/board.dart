import 'piece.dart';
import 'pos.dart';

class Board {
  Board(this.rows, this.cols, List<bool> playable)
      : assert(playable.length == rows * cols),
        _playable = List.of(playable),
        _cells = List<Piece?>.filled(rows * cols, null);

  final int rows;
  final int cols;
  final List<bool> _playable;
  final List<Piece?> _cells;

  /// Rows whose pieces cannot be swapped by hand (conveyor rows).
  Set<int> lockedRows = const {};

  bool isLocked(Pos p) => lockedRows.contains(p.row);

  /// Independent copy with fresh Piece objects (ids kept).
  Board copy() {
    final b = Board(rows, cols, _playable)..lockedRows = lockedRows;
    for (var i = 0; i < _cells.length; i++) {
      final p = _cells[i];
      if (p != null) {
        b._cells[i] = Piece(id: p.id, kind: p.kind, special: p.special)
          ..ice = p.ice;
      }
    }
    return b;
  }

  int _i(Pos p) => p.row * cols + p.col;

  bool inBounds(Pos p) =>
      p.row >= 0 && p.row < rows && p.col >= 0 && p.col < cols;

  /// False for out-of-bounds and void cells (and rice bags until broken).
  bool isPlayable(Pos p) => inBounds(p) && _playable[_i(p)];

  /// Turns a cell on once the rice bag that blocked it breaks.
  void openCell(Pos p) => _playable[_i(p)] = true;

  /// Kind used for matching: null for empty cells, Omakase and frozen pieces.
  PieceKind? matchKind(Pos p) {
    final piece = this[p];
    return piece == null || piece.frozen ? null : piece.kind;
  }

  Piece? operator [](Pos p) => inBounds(p) ? _cells[_i(p)] : null;

  void operator []=(Pos p, Piece? piece) {
    assert(isPlayable(p) || piece == null, 'Cannot place a piece on $p');
    _cells[_i(p)] = piece;
  }

  void swap(Pos a, Pos b) {
    final t = this[a];
    this[a] = this[b];
    this[b] = t;
  }

  /// All playable cells, row-major (top-left first).
  Iterable<Pos> get positions sync* {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final p = Pos(r, c);
        if (_playable[_i(p)]) yield p;
      }
    }
  }
}
