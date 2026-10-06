import 'package:sushi_match/core/board.dart';
import 'package:sushi_match/core/level.dart';
import 'package:sushi_match/core/piece.dart';
import 'package:sushi_match/core/pos.dart';

/// s=salmon m=maguro t=tamago i=ikura e=ebi k=kappa X=void .=empty
Board boardFrom(List<String> rows) {
  const map = {
    's': PieceKind.salmon,
    'm': PieceKind.maguro,
    't': PieceKind.tamago,
    'i': PieceKind.ikura,
    'e': PieceKind.ebi,
    'k': PieceKind.kappa,
  };
  final cols = rows.first.length;
  final b = Board(rows.length, cols, [
    for (final r in rows)
      for (final ch in r.split('')) ch != 'X'
  ]);
  var id = 0;
  for (var r = 0; r < rows.length; r++) {
    for (var c = 0; c < cols; c++) {
      final k = map[rows[r][c]];
      if (k != null) b[Pos(r, c)] = Piece(id: id++, kind: k);
    }
  }
  return b;
}

LevelConfig testLevel({int seed = 42, int moves = 30, int size = 7}) =>
    LevelConfig.fromJson({
      'id': 1,
      'board': {'cols': size, 'rows': size},
      'pieces': ['salmon', 'maguro', 'tamago', 'ikura', 'kappa'],
      'moves': moves,
      'goals': [
        {'type': 'collect', 'piece': 'salmon', 'count': 9999},
      ],
      'seed': seed,
    });
