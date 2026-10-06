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
