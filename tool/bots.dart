// Simple bots shared by tool/balance.dart and tool/tune.dart.
import 'dart:math';

import 'package:sushi_match/core/game_engine.dart';
import 'package:sushi_match/core/level.dart';
import 'package:sushi_match/core/match_finder.dart';
import 'package:sushi_match/core/move_finder.dart';
import 'package:sushi_match/core/pos.dart';

typedef Move = (Pos, Pos);

/// Picks any legal move.
Move random(GameEngine e, Random r) {
  final m = MoveFinder.allMoves(e.board);
  return m[r.nextInt(m.length)];
}

/// Picks the move that clears the most pieces right now, favouring pieces the
/// level asks for.
Move greedy(GameEngine e, Random r) {
  final wanted = {
    for (final g in e.level.goals)
      if (g.piece != null) g.piece,
  };
  final hasNori = e.level.goals.any((g) => g.type == GoalType.clearNori);
  final hasIce = e.level.goals.any((g) => g.type == GoalType.breakIce);
  final hasBag = e.level.goals
      .any((g) => g.type == GoalType.breakBag || g.type == GoalType.clearMats);
  final hasDeliver = e.level.goals.any((g) => g.type == GoalType.deliver);
  Move? best;
  var bestScore = -1.0;
  for (final m in MoveFinder.allMoves(e.board)) {
    final pa = e.board[m.$1]!, pb = e.board[m.$2]!;
    double s;
    if (pa.isSpecial || pb.isSpecial) {
      s = 12; // specials are strong
    } else {
      e.board.swap(m.$1, m.$2);
      s = 0;
      for (final g in MatchFinder.find(e.board, preferred: {m.$1, m.$2})) {
        for (final c in g.cells) {
          s += wanted.contains(g.kind) ? 1.5 : 1;
          if (hasNori && e.noriAt(c) > 0) s += 2;
          if (hasDeliver) {
            // Clearing under an ingredient lets it sink.
            for (var r = 0; r < c.row; r++) {
              if (e.board[Pos(r, c.col)]?.ingredient ?? false) s += 2;
            }
          }
          if (hasBag) {
            for (final d in const [
              Pos(0, 1),
              Pos(0, -1),
              Pos(1, 0),
              Pos(-1, 0)
            ]) {
              if (e.bagAt(c + d) > 0) s += 2;
            }
          }
          if (hasIce) {
            for (final d in const [
              Pos(0, 1),
              Pos(0, -1),
              Pos(1, 0),
              Pos(-1, 0)
            ]) {
              if (e.board[c + d]?.frozen ?? false) s += 2;
            }
          }
        }
        if (g.spawn != null) s += 4;
      }
      e.board.swap(m.$1, m.$2);
    }
    if (hasDeliver) {
      // Steer ingredients: a swap that lowers one is worth a lot.
      for (final (from, to) in [(m.$1, m.$2), (m.$2, m.$1)]) {
        if ((e.board[from]?.ingredient ?? false) && to.row > from.row) s += 6;
      }
    }
    s += r.nextDouble() * 0.5;
    if (s > bestScore) {
      bestScore = s;
      best = m;
    }
  }
  return best!;
}

/// One-move lookahead: tries every move on forked copies (so conveyor shifts,
/// cascades and refills all play out) and keeps the one that advances the
/// goals most. Two samples per move smooth out refill luck.
Move planner(GameEngine e, Random r) {
  double progress(GameEngine f) {
    var total = 0.0;
    for (final g in f.goals) {
      total += (g.current / g.goal.count).clamp(0.0, 1.0);
    }
    if (f.status == GameStatus.won) total += 10;
    if (f.status == GameStatus.lost) total -= 1;
    return total;
  }

  Move? best;
  var bestValue = double.negativeInfinity;
  for (final m in MoveFinder.allMoves(e.board)) {
    var value = 0.0;
    const samples = 2;
    for (var i = 0; i < samples; i++) {
      final f = e.fork(r.nextInt(1 << 30));
      f.trySwap(m.$1, m.$2);
      value += progress(f) / samples;
    }
    value += r.nextDouble() * 0.01;
    if (value > bestValue) {
      bestValue = value;
      best = m;
    }
  }
  return best!;
}

({bool won, int stars, int score}) play(
    LevelConfig level, int seed, Move Function(GameEngine, Random) bot) {
  final e = GameEngine(level, seed: seed);
  final r = Random(seed ^ 0x5eed);
  var guard = 0;
  while (e.status == GameStatus.playing &&
      guard++ < 200 &&
      MoveFinder.findMove(e.board) != null) {
    final m = bot(e, r);
    e.trySwap(m.$1, m.$2);
  }
  return (won: e.status == GameStatus.won, stars: e.stars, score: e.score);
}
