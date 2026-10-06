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
