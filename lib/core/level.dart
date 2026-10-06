import 'piece.dart';

enum GoalType { collect, score }

class LevelGoal {
  const LevelGoal.collect(PieceKind this.piece, this.count)
      : type = GoalType.collect;
  const LevelGoal.score(this.count)
      : type = GoalType.score,
        piece = null;

  final GoalType type;
  final PieceKind? piece;
  final int count;

  factory LevelGoal.fromJson(Map<String, dynamic> j) {
    switch (j['type']) {
      case 'collect':
        return LevelGoal.collect(
            PieceKind.values.byName(j['piece'] as String), j['count'] as int);
      case 'score':
        return LevelGoal.score(j['count'] as int);
      default:
        // clear_nori / deliver / break arrive together with their blockers.
        throw UnsupportedError(
            'Goal type "${j['type']}" is not implemented yet');
    }
  }
}

class LevelConfig {
  LevelConfig({
    required this.id,
    required this.rows,
    required this.cols,
    required this.playable,
    required this.pieces,
    required this.moves,
    required this.goals,
    required this.stars,
    required this.seed,
  });

  final int id;
  final int rows;
  final int cols;

  /// Row-major mask; false = void cell.
  final List<bool> playable;
  final List<PieceKind> pieces;
  final int moves;
  final List<LevelGoal> goals;
  final List<int> stars;
  final int seed;

  /// Parses the GDD level schema. Legend values other than "void" are
  /// treated as plain cells for now (nori, ice, ... come later).
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
    return LevelConfig(
      id: j['id'] as int,
      rows: rows,
      cols: cols,
      playable: [
        for (final line in layout)
          for (final ch in line.split('')) (legend[ch] ?? 'cell') != 'void',
      ],
      pieces: [
        for (final p in j['pieces'] as List)
          PieceKind.values.byName(p as String),
      ],
      moves: j['moves'] as int,
      goals: [
        for (final g in j['goals'] as List)
          LevelGoal.fromJson(g as Map<String, dynamic>),
      ],
      stars: (j['stars'] as List? ?? const []).cast<int>(),
      seed: j['seed'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
