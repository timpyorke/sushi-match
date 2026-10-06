import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/core/match_finder.dart' as mf;
import 'package:sushi_trio/core/piece.dart';
import 'package:sushi_trio/core/pos.dart';

import 'helpers.dart';

void main() {
  test('no match', () {
    expect(mf.MatchFinder.find(boardFrom(['smt', 'tis', 'mts'])), isEmpty);
  });

  test('void breaks a run', () {
    expect(mf.MatchFinder.find(boardFrom(['ssXs', 'mtim'])), isEmpty);
  });

  test('3 in a row clears without a special', () {
    final g = mf.MatchFinder.find(boardFrom(['sssmt', 'mtikm', 'tikmt']));
    expect(g, hasLength(1));
    expect(g.single.cells, hasLength(3));
    expect(g.single.spawn, isNull);
  });

  test('4 in a row makes a row knife at the swapped cell', () {
    final g = mf.MatchFinder.find(boardFrom(['ssssm', 'mtikt', 'tikmi']),
        preferred: {const Pos(0, 2)});
    expect(g.single.spawn, SpecialType.knifeRow);
    expect(g.single.spawnAt, const Pos(0, 2));
  });

  test('5 in a row makes omakase', () {
    final g = mf.MatchFinder.find(boardFrom(['sssss', 'mtikm', 'tikmt']));
    expect(g.single.spawn, SpecialType.omakase);
    expect(g.single.cells, hasLength(5));
  });

  test('L shape makes wasabi at the corner', () {
    final g = mf.MatchFinder.find(boardFrom(['smtik', 'stikm', 'sssmt']));
    expect(g.single.spawn, SpecialType.wasabi);
    expect(g.single.spawnAt, const Pos(2, 0));
    expect(g.single.cells, hasLength(5));
  });

  test('2x2 square makes soy fish', () {
    final g = mf.MatchFinder.find(boardFrom(['ssmt', 'ssik', 'tkmi']));
    expect(g.single.spawn, SpecialType.soyFish);
    expect(g.single.cells, hasLength(4));
  });
}
