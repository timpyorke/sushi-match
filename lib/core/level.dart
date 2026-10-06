import 'piece.dart';

enum GoalType { collect, score, clearNori }

class LevelGoal {
  const LevelGoal.collect(PieceKind this.piece, this.count)
      : type = GoalType.collect;
  const LevelGoal.score(this.count)
      : type = GoalType.score,
        piece = null;

  /// Clear every nori sheet; [count] is the number of sheeted cells.
  const LevelGoal.clearNori(this.count)
      : type = GoalType.clearNori,
        piece = null;

  final GoalType type;
  final PieceKind? piece;
  final int count;

  factory LevelGoal.fromJson(Map<String, dynamic> j, {int noriCells = 0}) {
    switch (j['type']) {
      case 'collect':
        return LevelGoal.collect(
            PieceKind.values.byName(j['piece'] as String), j['count'] as int);
      case 'score':
        return LevelGoal.score(j['count'] as int);
      case 'clear_nori':
        if (noriCells == 0) {
          throw const FormatException('clear_nori needs nori cells in layout');
        }
        return LevelGoal.clearNori(noriCells);
      default:
        // deliver / break arrive together with their blockers.
        throw UnsupportedError(
            'Goal type "${j['type']}" is not implemented yet');
    }
  }
}

/// A row whose pieces slide one cell in [dir] (-1 left, +1 right) every turn.
class Conveyor {
  const Conveyor(this.row, this.dir);
  final int row;
  final int dir;

  factory Conveyor.fromJson(Map<String, dynamic> j) {
    final dir = switch (j['dir']) {
      'left' => -1,
      'right' => 1,
      final d => throw FormatException('conveyor dir "$d" must be left/right'),
    };
    return Conveyor(j['row'] as int, dir);
  }
}

class LevelConfig {
  LevelConfig({
    required this.id,
    required this.rows,
    required this.cols,
    required this.playable,
    required this.nori,
    required this.pieces,
    required this.moves,
    required this.goals,
    required this.stars,
    required this.seed,
    this.conveyors = const [],
  });

  final int id;
  final int rows;
  final int cols;

  /// Row-major mask; false = void cell.
  final List<bool> playable;

  /// Row-major nori layers under each cell (0 = none).
  final List<int> nori;
  final List<PieceKind> pieces;
  final int moves;
  final List<LevelGoal> goals;
  final List<int> stars;
  final int seed;
  final List<Conveyor> conveyors;

  /// Parses the GDD level schema. `nori` / `nori:N` legend values put N
  /// layers under a cell; other values besides "void" are plain cells for now
  /// (ice, ... come later).
  factory LevelConfig.fromJson(Map<String, dynamic> j) {
    final board = j['board'] as Map<String, dynamic>;
    final rows = board['rows'] as int;
    final cols = board['cols'] as int;
    final layout =
        (j['layout'] as List?)?.cast<String>() ?? List.filled(rows, '.' * cols);
    final legend = (j['legend'] as Map?)?.cast<String, String>() ??
        const {'.': 'cell', 'X': 'void'};
    if (layout.length != rows || layout.any((l) => l.length != cols)) {
      throw FormatException('layout does not match board ${cols}x$rows');
    }
    final cellsOf = [
      for (final line in layout)
        for (final ch in line.split('')) legend[ch] ?? 'cell',
    ];
    final nori = [
      for (final v in cellsOf)
        v.startsWith('nori')
            ? (v.contains(':') ? int.parse(v.split(':')[1]) : 1)
            : 0,
    ];
    final conveyors = [
      for (final c in (j['conveyors'] as List? ?? const []))
        Conveyor.fromJson(c as Map<String, dynamic>),
    ];
    for (final c in conveyors) {
      if (c.row < 0 || c.row >= rows) {
        throw FormatException('conveyor row ${c.row} is off the board');
      }
    }
    return LevelConfig(
      id: j['id'] as int,
      rows: rows,
      cols: cols,
      playable: [for (final v in cellsOf) v != 'void'],
      nori: nori,
      pieces: [
        for (final p in j['pieces'] as List)
          PieceKind.values.byName(p as String),
      ],
      moves: j['moves'] as int,
      goals: [
        for (final g in j['goals'] as List)
          LevelGoal.fromJson(g as Map<String, dynamic>,
              noriCells: nori.where((n) => n > 0).length),
      ],
      stars: (j['stars'] as List? ?? const []).cast<int>(),
      conveyors: conveyors,
      seed: j['seed'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
