/// Immutable grid coordinate. Row 0 is the top of the board.
class Pos {
  const Pos(this.row, this.col);

  final int row;
  final int col;

  Pos operator +(Pos o) => Pos(row + o.row, col + o.col);

  Pos operator -(Pos o) => Pos(row - o.row, col - o.col);

  bool isAdjacentTo(Pos o) => (row - o.row).abs() + (col - o.col).abs() == 1;

  @override
  bool operator ==(Object other) =>
      other is Pos && other.row == row && other.col == col;

  @override
  int get hashCode => row * 1000 + col;

  @override
  String toString() => '($row,$col)';
}
