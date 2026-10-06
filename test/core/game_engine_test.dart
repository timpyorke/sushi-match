import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_match/core/game_engine.dart';
import 'package:sushi_match/core/level.dart';
import 'package:sushi_match/core/match_finder.dart' as mf;
import 'package:sushi_match/core/move_finder.dart';
import 'package:sushi_match/core/piece.dart';
import 'package:sushi_match/core/pos.dart';
import 'package:sushi_match/core/steps.dart';

import 'helpers.dart';

void main() {
  noriAndBoosterTests();
  conveyorTests();
  iceTests();
  bagTests();
  deliverAndMatTests();
  fireAndCatTests();
  keyBombGravityPortalTests();
  void expectStableBoard(GameEngine e) {
    final ids = <int>{};
    for (final p in e.board.positions) {
      final piece = e.board[p];
      expect(piece, isNotNull, reason: 'hole at $p');
      expect(ids.add(piece!.id), isTrue, reason: 'duplicate id at $p');
    }
    expect(mf.MatchFinder.find(e.board), isEmpty, reason: 'unresolved match');
  }

  test('initial board is full, clean and playable', () {
    for (var seed = 0; seed < 50; seed++) {
      final e = GameEngine(testLevel(seed: seed));
      expectStableBoard(e);
      expect(MoveFinder.findMove(e.board), isNotNull);
    }
  });

  test('same seed gives the same board', () {
    final a = GameEngine(testLevel(seed: 7)).board;
    final b = GameEngine(testLevel(seed: 7)).board;
    for (final p in a.positions) {
      expect(a[p]!.kind, b[p]!.kind);
    }
  });

  test('invalid swap returns pieces and costs no move', () {
    final e = GameEngine(testLevel());
    (Pos, Pos)? bad;
    for (final p in e.board.positions) {
      final q = Pos(p.row, p.col + 1);
      if (!e.board.isPlayable(q)) continue;
      e.board.swap(p, q);
      final none = mf.MatchFinder.find(e.board).isEmpty;
      e.board.swap(p, q);
      if (none) {
        bad = (p, q);
        break;
      }
    }
    final before = e.board[bad!.$1]!.id;
    final steps = e.trySwap(bad.$1, bad.$2);
    expect(steps.single, isA<InvalidSwapStep>());
    expect(e.movesLeft, 30);
    expect(e.board[bad.$1]!.id, before);
  });

  test('random play keeps the board consistent', () {
    final rng = Random(1);
    var e = GameEngine(testLevel(seed: 0, moves: 40));
    var specials = 0;
    for (var i = 0; i < 400; i++) {
      if (e.status != GameStatus.playing) {
        e = GameEngine(testLevel(seed: i, moves: 40));
      }
      final moves = MoveFinder.allMoves(e.board);
      expect(moves, isNotEmpty);
      final (a, b) = moves[rng.nextInt(moves.length)];
      final before = e.movesLeft;
      final steps = e.trySwap(a, b);
      expect(steps.first, isA<SwapStep>());
      expect(steps.last, isA<TurnEndStep>());
      expect(e.movesLeft, before - 1);
      specials += steps.whereType<SpecialActivateStep>().length;
      expectStableBoard(e);
    }
    expect(specials, greaterThan(0), reason: 'specials never fired');
  });

  test('cascade multiplier grows', () {
    final rng = Random(3);
    final e = GameEngine(testLevel(seed: 3, moves: 999));
    var sawCascade = false;
    for (var i = 0; i < 300 && !sawCascade; i++) {
      final moves = MoveFinder.allMoves(e.board);
      final (a, b) = moves[rng.nextInt(moves.length)];
      final clears = e.trySwap(a, b).whereType<ClearStep>().toList();
      if (clears.length > 1) {
        sawCascade = true;
        expect(clears.last.cascade, greaterThan(clears.first.cascade));
      }
    }
    expect(sawCascade, isTrue);
  });

  test('wasabi blasts a second time after the board settles', () {
    var sawSecondBlast = false;
    final moves = MoveFinder.allMoves(GameEngine(testLevel(seed: 5)).board);
    for (final (a, b) in moves) {
      final e = GameEngine(testLevel(seed: 5, moves: 99));
      e.board[a]!.special = SpecialType.wasabi;
      final blasts = e
          .trySwap(a, b)
          .whereType<SpecialActivateStep>()
          .where((s) => s.type == SpecialType.wasabi && s.origin == b)
          .length;
      if (blasts >= 2) {
        sawSecondBlast = true;
        break;
      }
    }
    expect(sawSecondBlast, isTrue);
  });

  test('leftover moves become a bonus round on win', () {
    final level = LevelConfig.fromJson({
      'id': 1,
      'board': {'cols': 7, 'rows': 7},
      'pieces': ['salmon', 'maguro', 'tamago', 'ikura', 'kappa'],
      'moves': 30,
      'goals': [
        {'type': 'score', 'count': 1},
      ],
      'seed': 1,
    });
    final e = GameEngine(level);
    final (a, b) = MoveFinder.allMoves(e.board).first;
    final steps = e.trySwap(a, b);
    expect(e.status, GameStatus.won);
    expect(steps.whereType<TransformStep>(), isNotEmpty);
    expect(steps.whereType<SpecialActivateStep>(), isNotEmpty);
    expect(e.movesLeft, 0);
    expect((steps.last as TurnEndStep).movesLeft, 0);
  });
}

LevelConfig _noriLevel() => LevelConfig.fromJson({
      'id': 1,
      'board': {'cols': 7, 'rows': 7},
      'layout': [
        '.......',
        '.......',
        '.......',
        '...N...',
        '.......',
        '.......',
        '.......',
      ],
      'legend': {'.': 'cell', 'N': 'nori:2'},
      'pieces': ['salmon', 'maguro', 'tamago', 'ikura', 'kappa'],
      'moves': 99,
      'goals': [
        {'type': 'clear_nori'},
      ],
      'seed': 1,
    });

void noriAndBoosterTests() {
  group('nori', () {
    test('parses layers and goal size', () {
      final level = _noriLevel();
      expect(level.nori.where((n) => n > 0), [2]);
      expect(level.goals.single.type, GoalType.clearNori);
      expect(level.goals.single.count, 1);
    });

    test('clearing the cell twice removes it and meets the goal', () {
      final e = GameEngine(_noriLevel());
      const cell = Pos(3, 3);
      expect(e.noriAt(cell), 2);
      e.useChopsticks(cell);
      expect(e.noriAt(cell), 1);
      expect(e.goals.single.done, isFalse);
      e.useChopsticks(cell);
      expect(e.noriAt(cell), 0);
      expect(e.goals.single.done, isTrue);
      expect(e.status, GameStatus.won);
    });
  });

  group('boosters', () {
    test('chopsticks and shuffle cost no move', () {
      final e = GameEngine(testLevel(seed: 4, moves: 10));
      e.useChopsticks(const Pos(2, 2));
      expect(e.movesLeft, 10);
      final steps = e.useShuffle();
      expect(steps.first, isA<ShuffleStep>());
      expect(e.movesLeft, 10);
      expect(MoveFinder.findMove(e.board), isNotNull);
    });

    test('free swap swaps non-adjacent pieces without spending a move', () {
      final e = GameEngine(testLevel(seed: 4, moves: 10));
      const a = Pos(0, 1), b = Pos(5, 5);
      final ida = e.board[a]!.id;
      final steps = e.useFreeSwap(a, b);
      expect(steps.first, isA<SwapStep>());
      expect(e.movesLeft, 10);
      expect(steps.last, isA<TurnEndStep>());
      // The piece may have been cleared by a match, but if it still exists it
      // must no longer sit at a.
      expect(e.board[a]?.id, isNot(ida));
    });

    test('extra moves revive a lost level', () {
      final e = GameEngine(testLevel(seed: 4, moves: 1));
      final (a, b) = MoveFinder.allMoves(e.board).first;
      e.trySwap(a, b);
      expect(e.status, GameStatus.lost);
      e.addMoves(5);
      expect(e.status, GameStatus.playing);
      expect(e.movesLeft, 5);
    });
  });
}

void conveyorTests() {
  test('belt rows are locked: no hand swaps, no suggested moves', () {
    final level = LevelConfig.fromJson({
      'id': 97,
      'board': {'cols': 7, 'rows': 7},
      'pieces': ['salmon', 'maguro', 'tamago', 'ikura', 'kappa'],
      'moves': 30,
      'goals': [
        {'type': 'score', 'count': 999999},
      ],
      'conveyors': [
        {'row': 3, 'dir': 'right'},
      ],
      'seed': 9,
    });
    final e = GameEngine(level);
    expect(MoveFinder.findMove(e.board), isNotNull);
    for (final m in MoveFinder.allMoves(e.board)) {
      expect(m.$1.row, isNot(3));
      expect(m.$2.row, isNot(3));
    }
    final ids = {for (final p in e.board.positions) p: e.board[p]!.id};
    for (final (a, b) in [
      (const Pos(3, 2), const Pos(3, 3)),
      (const Pos(2, 2), const Pos(3, 2)),
    ]) {
      expect(e.trySwap(a, b).single, isA<InvalidSwapStep>());
    }
    expect(e.movesLeft, 30);
    expect({for (final p in e.board.positions) p: e.board[p]!.id}, ids);
  });

  test('clears caused by the belt itself earn no score', () {
    final level = LevelConfig.fromJson({
      'id': 98,
      'board': {'cols': 7, 'rows': 7},
      'pieces': ['salmon', 'maguro', 'tamago', 'ikura'],
      'moves': 60,
      'goals': [
        {'type': 'score', 'count': 999999},
      ],
      'conveyors': [
        {'row': 3, 'dir': 'right'},
        {'row': 5, 'dir': 'left'},
      ],
      'seed': 3,
    });
    var spoiled = 0;
    for (var seed = 0; seed < 40; seed++) {
      final e = GameEngine(level, seed: seed);
      var scored = 0;
      for (var turn = 0; turn < 15 && e.status == GameStatus.playing; turn++) {
        final m = MoveFinder.findMove(e.board)!;
        final steps = e.trySwap(m.$1, m.$2);
        final belt = steps.indexWhere((s) => s is ConveyorStep);
        for (var i = 0; i < steps.length; i++) {
          final s = steps[i];
          if (s is! ClearStep) continue;
          scored += s.scoreGained;
          if (belt >= 0 && i > belt) {
            spoiled++;
            expect(s.scoreGained, 0);
          }
        }
      }
      expect(e.score, scored);
    }
    expect(spoiled, greaterThan(0), reason: 'belts never matched anything');
  });

  test('fork copies the state and plays on without touching the original', () {
    final e = GameEngine(testLevel(seed: 8));
    final f = e.fork(1);
    for (final p in e.board.positions) {
      expect(f.board[p]!.id, e.board[p]!.id);
      expect(identical(f.board[p], e.board[p]), isFalse);
    }
    final before = {for (final p in e.board.positions) p: e.board[p]!.id};
    final move = MoveFinder.findMove(f.board)!;
    f.trySwap(move.$1, move.$2);
    expect(f.movesLeft, e.movesLeft - 1);
    expect(e.score, 0);
    expect({for (final p in e.board.positions) p: e.board[p]!.id}, before);
  });

  test('conveyor shifts its row each turn and keeps the board stable', () {
    final level = LevelConfig.fromJson({
      'id': 99,
      'board': {'cols': 7, 'rows': 7},
      'pieces': ['salmon', 'maguro', 'tamago', 'ikura', 'kappa'],
      'moves': 30,
      'goals': [
        {'type': 'collect', 'piece': 'salmon', 'count': 9999},
      ],
      'conveyors': [
        {'row': 3, 'dir': 'right'},
      ],
      'seed': 5,
    });
    final e = GameEngine(level);
    expect(level.conveyors.single.dir, 1);
    final move = MoveFinder.findMove(e.board)!;
    final steps = e.trySwap(move.$1, move.$2);
    expect(steps.whereType<ConveyorStep>(), isNotEmpty);
    final ids = {for (final p in e.board.positions) e.board[p]!.id};
    expect(ids.length, 49);
    expect(mf.MatchFinder.find(e.board), isEmpty);
  });
}

LevelConfig _iceLevel() => LevelConfig.fromJson({
      'id': 1,
      'board': {'cols': 7, 'rows': 7},
      'layout': [
        '.......',
        '.......',
        '.......',
        '...I...',
        '.......',
        '.......',
        '.......',
      ],
      'legend': {'.': 'cell', 'I': 'ice:2'},
      'pieces': ['salmon', 'maguro', 'tamago', 'ikura', 'kappa'],
      'moves': 99,
      'goals': [
        {'type': 'break_ice'},
      ],
      'seed': 1,
    });

void iceTests() {
  group('ice', () {
    test('parses layers and goal size; starts the piece frozen', () {
      final level = _iceLevel();
      expect(level.ice.where((n) => n > 0), [2]);
      expect(level.goals.single.type, GoalType.breakIce);
      expect(level.goals.single.count, 1);
      final e = GameEngine(level);
      expect(e.board[const Pos(3, 3)]!.ice, 2);
      expect(e.goals.single.current, 0);
    });

    test('frozen pieces cannot be swapped by hand', () {
      final e = GameEngine(_iceLevel());
      final steps = e.trySwap(const Pos(3, 3), const Pos(3, 4));
      expect(steps.single, isA<InvalidSwapStep>());
      expect(e.movesLeft, 99);
      expect(e.useFreeSwap(const Pos(3, 3), const Pos(0, 0)), isEmpty);
    });

    test('frozen pieces neither match nor offer moves', () {
      final b = boardFrom(['sss', 'mtm', 'tmt']);
      expect(mf.MatchFinder.find(b), hasLength(1));
      b[const Pos(0, 1)]!.ice = 1;
      expect(mf.MatchFinder.find(b), isEmpty);
    });

    test('a clear next to the ice cracks it layer by layer', () {
      final e = GameEngine(_iceLevel());
      final id = e.board[const Pos(3, 3)]!.id;
      Pos where() => e.board.positions.firstWhere((p) => e.board[p]!.id == id);
      final steps = e.useChopsticks(const Pos(3, 2));
      // Cascades from the refill may crack it again, but never skip a layer.
      expect(steps.whereType<IceStep>().first.hits.single.layers, 1);
      for (var i = 0; i < 20 && !e.goals.single.done; i++) {
        e.useChopsticks(where() + const Pos(0, 1));
      }
      expect(e.goals.single.done, isTrue);
      expect(e.status, GameStatus.won);
    });

    test('chopsticks on the ice itself crack it without clearing the piece',
        () {
      final e = GameEngine(_iceLevel());
      final id = e.board[const Pos(3, 3)]!.id;
      e.useChopsticks(const Pos(3, 3));
      final at = e.board.positions.firstWhere((p) => e.board[p]!.id == id);
      expect(e.board[at]!.ice, 1);
    });
  });
}

LevelConfig _bagLevel({int layers = 1}) => LevelConfig.fromJson({
      'id': 1,
      'board': {'cols': 7, 'rows': 7},
      'layout': [
        '.......',
        '.......',
        '.......',
        '...B...',
        '.......',
        '.......',
        '.......',
      ],
      'legend': {'.': 'cell', 'B': 'bag:$layers'},
      'pieces': ['salmon', 'maguro', 'tamago', 'ikura', 'kappa'],
      'moves': 99,
      'goals': [
        {'type': 'break_bag'},
      ],
      'seed': 3,
    });

void bagTests() {
  group('rice bag', () {
    void expectFull(GameEngine e) {
      for (final p in e.board.positions) {
        expect(e.board[p], isNotNull, reason: 'hole at $p');
      }
      expect(mf.MatchFinder.find(e.board), isEmpty);
    }

    test('parses: the bagged cell is closed and the goal counts bags', () {
      final level = _bagLevel(layers: 2);
      expect(level.bags.where((n) => n > 0), [2]);
      expect(level.goals.single.type, GoalType.breakBag);
      expect(level.goals.single.count, 1);
      final e = GameEngine(level);
      expect(e.board.isPlayable(const Pos(3, 3)), isFalse);
      expect(e.bagAt(const Pos(3, 3)), 2);
      expect(e.goals.single.done, isFalse);
    });

    test('the cell under a bag refills from the side, not from above', () {
      final e = GameEngine(_bagLevel());
      // (4,3) sits directly below the sack, so only a diagonal slide can
      // fill it; the sack's own cell must stay closed meanwhile.
      e.useChopsticks(const Pos(4, 3));
      expectFull(e);
    });

    test('a clear next to the bag cracks it, opens the cell and wins', () {
      final e = GameEngine(_bagLevel());
      final steps = e.useChopsticks(const Pos(3, 2));
      expect(steps.whereType<BagStep>().first.hits.single.layers, 0);
      expect(e.board.isPlayable(const Pos(3, 3)), isTrue);
      expect(e.board[const Pos(3, 3)], isNotNull);
      expect(e.goals.single.done, isTrue);
      expect(e.status, GameStatus.won);
    });

    test('two layers need two clears', () {
      final e = GameEngine(_bagLevel(layers: 2));
      e.useChopsticks(const Pos(3, 2));
      expect(e.bagAt(const Pos(3, 3)), 1);
      expect(e.goals.single.done, isFalse);
    });

    test('random play keeps every open cell filled', () {
      final e = GameEngine(_bagLevel(layers: 3));
      final rng = Random(5);
      for (var i = 0; i < 60 && e.status == GameStatus.playing; i++) {
        final moves = MoveFinder.allMoves(e.board);
        final m = moves[rng.nextInt(moves.length)];
        e.trySwap(m.$1, m.$2);
        expectFull(e);
      }
    });
  });
}

LevelConfig _deliverLevel({int count = 1}) => LevelConfig.fromJson({
      'id': 1,
      'board': {'cols': 7, 'rows': 7},
      'pieces': ['salmon', 'maguro', 'tamago', 'ikura', 'kappa'],
      'moves': 99,
      'goals': [
        {'type': 'deliver', 'count': count},
      ],
      'seed': 11,
    });

LevelConfig _matLevel() => LevelConfig.fromJson({
      'id': 1,
      'board': {'cols': 7, 'rows': 7},
      'layout': [
        '.......',
        '.......',
        '.......',
        '...T...',
        '.......',
        '.......',
        '.......',
      ],
      'legend': {'.': 'cell', 'T': 'mat'},
      'pieces': ['salmon', 'maguro', 'tamago', 'ikura', 'kappa'],
      'moves': 99,
      'goals': [
        {'type': 'clear_mats'},
      ],
      'seed': 7,
    });

void deliverAndMatTests() {
  group('deliver', () {
    Pos? ingredientAt(GameEngine e) {
      for (final p in e.board.positions) {
        if (e.board[p]?.ingredient ?? false) return p;
      }
      return null;
    }

    test('starts with an ingredient in the upper half that never matches', () {
      final e = GameEngine(_deliverLevel());
      final at = ingredientAt(e);
      expect(at, isNotNull);
      expect(at!.row, lessThan(4));
      expect(mf.MatchFinder.find(e.board), isEmpty);
      expect(e.useChopsticks(at), isEmpty);
    });

    test('an ingredient that reaches the bottom row is delivered', () {
      final e = GameEngine(_deliverLevel());
      for (var i = 0; i < 30 && !e.goals.single.done; i++) {
        final at = ingredientAt(e)!;
        final steps = e.useChopsticks(Pos(at.row + 1, at.col));
        if (e.goals.single.done) {
          expect(steps.whereType<DeliverStep>(), isNotEmpty);
        }
      }
      expect(e.goals.single.done, isTrue);
      expect(e.status, GameStatus.won);
    });

    test('no more ingredients appear than the goal asks for', () {
      final e = GameEngine(_deliverLevel(count: 2));
      final rng = Random(2);
      var seen = 0;
      for (var i = 0; i < 80 && e.status == GameStatus.playing; i++) {
        final ing = [
          for (final p in e.board.positions)
            if (e.board[p]?.ingredient ?? false) p,
        ];
        expect(ing.length, lessThanOrEqualTo(2));
        seen = max(seen, e.goals.single.current + ing.length);
        final moves = MoveFinder.allMoves(e.board);
        final m = moves[rng.nextInt(moves.length)];
        e.trySwap(m.$1, m.$2);
      }
      expect(seen, lessThanOrEqualTo(2));
    });
  });

  group('bamboo mat', () {
    test('parses: the mat cell is closed and counts toward the goal', () {
      final e = GameEngine(_matLevel());
      expect(e.board.isPlayable(const Pos(3, 3)), isFalse);
      expect(e.matAt(const Pos(3, 3)), isTrue);
      expect(e.goals.single.goal.type, GoalType.clearMats);
      expect(e.goals.single.goal.count, 1);
      expect(e.goals.single.done, isFalse);
    });

    test('a clear next to the mat removes it and wins', () {
      final e = GameEngine(_matLevel());
      final steps = e.useChopsticks(const Pos(3, 2));
      expect(steps.whereType<BagStep>().first.hits.single.mat, isTrue);
      expect(e.matAt(const Pos(3, 3)), isFalse);
      expect(e.goals.single.done, isTrue);
    });

    test('a move that destroys no mat lets one spread', () {
      final e = GameEngine(_matLevel());
      final far = MoveFinder.allMoves(e.board).firstWhere((m) =>
          (m.$1.row - 3).abs() + (m.$1.col - 3).abs() > 4 &&
          (m.$2.row - 3).abs() + (m.$2.col - 3).abs() > 4);
      final steps = e.trySwap(far.$1, far.$2);
      final broke = steps.whereType<BagStep>().isNotEmpty;
      final mats = [
        for (var r = 0; r < 7; r++)
          for (var c = 0; c < 7; c++)
            if (e.matAt(Pos(r, c))) Pos(r, c),
      ];
      if (broke) {
        expect(mats, isEmpty);
      } else {
        expect(steps.whereType<MatSpreadStep>(), hasLength(1));
        expect(mats, hasLength(2));
        expect(e.board.isPlayable(mats.last), isFalse);
      }
    });

    test('the board stays consistent while mats spread', () {
      final e = GameEngine(_matLevel());
      final rng = Random(9);
      for (var i = 0; i < 40 && e.status == GameStatus.playing; i++) {
        final moves = MoveFinder.allMoves(e.board);
        if (moves.isEmpty) break;
        final m = moves[rng.nextInt(moves.length)];
        e.trySwap(m.$1, m.$2);
        final ids = <int>{};
        for (final p in e.board.positions) {
          final piece = e.board[p];
          if (piece != null) expect(ids.add(piece.id), isTrue);
        }
        expect(mf.MatchFinder.find(e.board), isEmpty);
      }
    });
  });
}

LevelConfig _fireLevel() => LevelConfig.fromJson({
      'id': 1,
      'board': {'cols': 7, 'rows': 7},
      'layout': [
        '.......',
        '.......',
        '.......',
        '...F...',
        '.......',
        '.......',
        '.......',
      ],
      'legend': {'.': 'cell', 'F': 'fire'},
      'pieces': ['salmon', 'maguro', 'tamago', 'ikura', 'kappa'],
      'moves': 99,
      'goals': [
        {'type': 'put_out'},
      ],
      'seed': 5,
    });

LevelConfig _catLevel({int lives = 2}) => LevelConfig.fromJson({
      'id': 1,
      'board': {'cols': 7, 'rows': 7},
      'layout': [
        '.......',
        '.......',
        '.......',
        '...C...',
        '.......',
        '.......',
        '.......',
      ],
      'legend': {'.': 'cell', 'C': 'cat:$lives'},
      'pieces': ['salmon', 'maguro', 'tamago', 'ikura', 'kappa'],
      'moves': 99,
      'goals': [
        {'type': 'shoo_cats'},
      ],
      'seed': 5,
    });

void fireAndCatTests() {
  int burning(GameEngine e) =>
      e.board.positions.where((p) => e.board[p]!.burning).length;

  group('grill fire', () {
    test('parses: the piece starts burning and the goal counts fires', () {
      final e = GameEngine(_fireLevel());
      expect(e.board[const Pos(3, 3)]!.burning, isTrue);
      expect(burning(e), 1);
      expect(e.goals.single.goal.type, GoalType.putOut);
      expect(e.goals.single.done, isFalse);
    });

    test('clearing the burning piece puts the fire out and wins', () {
      final e = GameEngine(_fireLevel());
      e.useChopsticks(const Pos(3, 3));
      expect(burning(e), 0);
      expect(e.goals.single.done, isTrue);
    });

    test('a move that puts nothing out lets the fire spread', () {
      final e = GameEngine(_fireLevel());
      final far = MoveFinder.allMoves(e.board).firstWhere((m) =>
          (m.$1.row - 3).abs() + (m.$1.col - 3).abs() > 3 &&
          (m.$2.row - 3).abs() + (m.$2.col - 3).abs() > 3);
      final steps = e.trySwap(far.$1, far.$2);
      if (burning(e) == 0) return; // a cascade happened to douse it
      expect(steps.whereType<IgniteStep>(), hasLength(1));
      expect(burning(e), greaterThanOrEqualTo(2));
    });

    test('random play keeps the board consistent while fire spreads', () {
      final e = GameEngine(_fireLevel());
      final rng = Random(4);
      for (var i = 0; i < 40 && e.status == GameStatus.playing; i++) {
        final moves = MoveFinder.allMoves(e.board);
        final m = moves[rng.nextInt(moves.length)];
        e.trySwap(m.$1, m.$2);
        for (final p in e.board.positions) {
          expect(e.board[p], isNotNull);
        }
      }
    });
  });

  group('thieving cat', () {
    test('parses: one cat with its lives', () {
      final e = GameEngine(_catLevel());
      expect(e.cats.single.hp, 2);
      expect(e.cats.single.pos, const Pos(3, 3));
      expect(e.goals.single.goal.type, GoalType.shooCats);
      expect(e.goals.single.goal.count, 1);
    });

    test('clears beside the cat startle it until it runs off', () {
      final e = GameEngine(_catLevel());
      final steps = e.useChopsticks(const Pos(3, 2));
      expect(steps.whereType<CatHitStep>().first.hits.single.hp, 1);
      expect(e.goals.single.done, isFalse);
      e.useChopsticks(const Pos(3, 4));
      expect(e.cats, isEmpty);
      expect(e.goals.single.done, isTrue);
    });

    test('an unstartled cat steps over and eats a piece, for no credit', () {
      final e = GameEngine(_catLevel(lives: 3));
      final far = MoveFinder.allMoves(e.board).firstWhere((m) =>
          (m.$1.row - 3).abs() + (m.$1.col - 3).abs() > 3 &&
          (m.$2.row - 3).abs() + (m.$2.col - 3).abs() > 3);
      final steps = e.trySwap(far.$1, far.$2);
      if (steps.whereType<CatHitStep>().isNotEmpty) return; // startled
      final move = steps.whereType<CatMoveStep>().single;
      expect(move.from, const Pos(3, 3));
      expect(move.from.isAdjacentTo(move.to), isTrue);
      expect(e.cats.single.pos, move.to);
      for (final p in e.board.positions) {
        expect(e.board[p], isNotNull);
      }
    });

    test('the board stays consistent while the cat prowls', () {
      final e = GameEngine(_catLevel(lives: 3));
      final rng = Random(6);
      for (var i = 0; i < 40 && e.status == GameStatus.playing; i++) {
        final moves = MoveFinder.allMoves(e.board);
        if (moves.isEmpty) break;
        final m = moves[rng.nextInt(moves.length)];
        e.trySwap(m.$1, m.$2);
        final ids = <int>{};
        for (final p in e.board.positions) {
          expect(ids.add(e.board[p]!.id), isTrue);
        }
      }
    });
  });
}

LevelConfig _levelWith(
        {List<String>? layout,
        Map<String, String>? legend,
        String gravity = 'down',
        int size = 7,
        List<Map<String, dynamic>>? goals}) =>
    LevelConfig.fromJson({
      'id': 1,
      'board': {'cols': size, 'rows': size},
      'layout': layout,
      'legend': legend ?? {'.': 'cell'},
      'gravity': gravity,
      'pieces': ['salmon', 'maguro', 'tamago', 'ikura', 'kappa'],
      'moves': 99,
      'goals': goals ??
          [
            {'type': 'score', 'count': 999999},
          ],
      'seed': 8,
    });

List<String> _plain([Map<String, String> put = const {}]) => [
      for (var r = 0; r < 7; r++)
        [for (var c = 0; c < 7; c++) put['$r,$c'] ?? '.'].join(),
    ];

void keyBombGravityPortalTests() {
  void expectFull(GameEngine e) {
    final ids = <int>{};
    for (final p in e.board.positions) {
      expect(e.board[p], isNotNull, reason: 'hole at $p');
      expect(ids.add(e.board[p]!.id), isTrue);
    }
  }

  group('key lock', () {
    LevelConfig lockLevel() => _levelWith(
        layout: _plain({'3,3': 'K'}), legend: {'.': 'cell', 'K': 'key:salmon'});

    test('a locked cell cannot be swapped until its colour is matched', () {
      final e = GameEngine(lockLevel());
      expect(e.board.isLocked(const Pos(3, 3)), isTrue);
      expect(e.trySwap(const Pos(3, 3), const Pos(3, 4)).single,
          isA<InvalidSwapStep>());
      final salmon = e.board.positions
          .firstWhere((p) => e.board[p]!.kind == PieceKind.salmon);
      final steps = e.useChopsticks(salmon);
      expect(steps.whereType<UnlockStep>().single.kind, PieceKind.salmon);
      expect(e.board.isLocked(const Pos(3, 3)), isFalse);
    });

    test('other colours leave it locked', () {
      final e = GameEngine(lockLevel());
      final other = e.board.positions
          .firstWhere((p) => e.board[p]!.kind == PieceKind.maguro);
      e.useChopsticks(other);
      expect(e.board.isLocked(const Pos(3, 3)), isTrue);
    });
  });

  group('time bomb', () {
    LevelConfig bombLevel(int n) => _levelWith(
        layout: _plain({'3,3': 'B'}), legend: {'.': 'cell', 'B': 'bomb:$n'});

    test('parses onto the starting piece', () {
      final e = GameEngine(bombLevel(3));
      expect(e.board[const Pos(3, 3)]!.timer, 3);
    });

    test('ticks every move and ends the level when it runs out', () {
      final e = GameEngine(bombLevel(1));
      final far = MoveFinder.allMoves(e.board).firstWhere((m) =>
          (m.$1.row - 3).abs() + (m.$1.col - 3).abs() > 3 &&
          (m.$2.row - 3).abs() + (m.$2.col - 3).abs() > 3);
      final steps = e.trySwap(far.$1, far.$2);
      final bomb = steps.whereType<BombStep>();
      if (bomb.isEmpty) return; // a cascade defused it
      expect(bomb.first.exploded, hasLength(1));
      expect(e.status, GameStatus.lost);
      expectFull(e);
      e.addMoves(5);
      expect(e.status, GameStatus.playing);
    });

    test('matching the bomb defuses it', () {
      final e = GameEngine(bombLevel(1));
      e.useChopsticks(const Pos(3, 3));
      final far = MoveFinder.allMoves(e.board).first;
      final steps = e.trySwap(far.$1, far.$2);
      expect(steps.whereType<BombStep>(), isEmpty);
      expect(e.status, GameStatus.playing);
    });
  });

  group('gravity', () {
    for (final (dir, rowStart, colStart) in [
      ('left', null, 7),
      ('right', null, -1),
      ('up', 7, null),
    ]) {
      test('$dir: pieces fall that way and refill from the far edge', () {
        final e = GameEngine(_levelWith(layout: _plain(), gravity: dir));
        final steps = e.useChopsticks(const Pos(3, 3));
        final refill = steps.whereType<RefillStep>().first.pieces.first;
        if (rowStart != null) {
          expect(refill.start.row, greaterThanOrEqualTo(rowStart));
        }
        if (colStart != null) {
          expect(colStart == 7 ? refill.start.col >= 7 : refill.start.col < 0,
              isTrue);
        }
        expectFull(e);
      });

      test('$dir: random play keeps the board full', () {
        final e = GameEngine(_levelWith(layout: _plain(), gravity: dir));
        final rng = Random(3);
        for (var i = 0; i < 30 && e.status == GameStatus.playing; i++) {
          final moves = MoveFinder.allMoves(e.board);
          final m = moves[rng.nextInt(moves.length)];
          e.trySwap(m.$1, m.$2);
          expectFull(e);
          expect(mf.MatchFinder.find(e.board), isEmpty);
        }
      });
    }
  });

  group('portal', () {
    LevelConfig portalLevel() => _levelWith(
        layout: _plain({'6,0': 'I', '0,6': 'O'}),
        legend: {'.': 'cell', 'I': 'portal_in:1', 'O': 'portal_out:1'});

    test('the entry is closed and a piece flows through to the exit', () {
      final e = GameEngine(portalLevel());
      expect(e.board.isPlayable(const Pos(6, 0)), isFalse);
      final entryTop = e.board[const Pos(5, 0)]!.id;
      final steps = e.useChopsticks(const Pos(4, 6));
      expectFull(e);
      final moves = [
        for (final s in steps.whereType<FallStep>()) ...s.moves,
      ];
      expect(moves.any((m) => m.pieceId == entryTop && m.to.col == 6), isTrue);
    });

    test('random play keeps every open cell filled', () {
      final e = GameEngine(portalLevel());
      final rng = Random(12);
      for (var i = 0; i < 40 && e.status == GameStatus.playing; i++) {
        final moves = MoveFinder.allMoves(e.board);
        final m = moves[rng.nextInt(moves.length)];
        e.trySwap(m.$1, m.$2);
        expectFull(e);
      }
    });
  });
}
