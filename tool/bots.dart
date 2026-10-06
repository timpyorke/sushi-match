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
        }
        if (g.spawn != null) s += 4;
      }
      e.board.swap(m.$1, m.$2);
    }
    s += r.nextDouble() * 0.5;
    if (s > bestScore) {
      bestScore = s;
      best = m;
    }
  }
  return best!;
}

({bool won, int stars, int score}) play(LevelConfig level, int seed, Move Function(GameEngine, Random) bot) {
  final e = GameEngine(level, seed: seed);
  final r = Random(seed ^ 0x5eed);
  var guard = 0;
  while (e.status == GameStatus.playing && guard++ < 200) {
    final m = bot(e, r);
    e.trySwap(m.$1, m.$2);
  }
  return (won: e.status == GameStatus.won, stars: e.stars, score: e.score);
}

