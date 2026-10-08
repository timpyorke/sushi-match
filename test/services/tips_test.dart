import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/core/level.dart';
import 'package:sushi_trio/services/tips.dart';

import '../core/helpers.dart';

LevelConfig _level(List<String> layout, Map<String, String> legend) =>
    LevelConfig.fromJson({
      'id': 1,
      'board': {'cols': layout.first.length, 'rows': layout.length},
      'layout': layout,
      'legend': {'.': 'cell', ...legend},
      'pieces': ['salmon', 'maguro', 'tamago', 'ikura', 'kappa'],
      'moves': 20,
      'goals': [
        {'type': 'score', 'count': 1000},
      ],
      'seed': 1,
    });

void main() {
  test('a plain level needs no tip', () {
    expect(tipFor(testLevel(), const {}), isNull);
  });

  test('the first unseen mechanic is explained, then the next', () {
    final level = _level(['.....', '.I...', '...B.', '.....', '.....'],
        {'I': 'ice:1', 'B': 'bag:1'});
    expect(tipFor(level, const {}), ('ice', 'tipIce'));
    expect(tipFor(level, const {'ice'}), ('bag', 'tipBag'));
    expect(tipFor(level, const {'ice', 'bag'}), isNull);
  });

  test('a mat is not mistaken for a rice bag', () {
    final level =
        _level(['.....', '..M..', '.....', '.....', '.....'], {'M': 'mat'});
    expect(tipFor(level, const {}), ('mat', 'tipMat'));
    expect(tipFor(level, const {'mat'}), isNull);
  });
}
