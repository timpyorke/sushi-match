// ignore_for_file: avoid_print
// Sets each level's `moves`, goal counts and `stars` so a greedy bot hits a difficulty
// curve: win rate falls from 98% (level 1) to 68% (level 20); the share of
// plays reaching 3 stars falls from 50% to 15%. Moves follow a fixed schedule
// and goal counts are scaled to fit. Humans out-plan the bot, so
// real players will find levels a little easier than the targets.
//
//   dart run tool/tune.dart [runs=150] [level ...] [--write]
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:sushi_match/core/level.dart';

import 'bots.dart';

const _tuneSeed = 1000;

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// [factor] scales every collect / score goal; nori goals stay as laid out.
LevelConfig _variant(LevelConfig l, int moves, double factor) => LevelConfig(
      id: l.id,
      rows: l.rows,
      cols: l.cols,
      playable: l.playable,
      nori: l.nori,
      pieces: l.pieces,
      moves: moves,
      goals: [for (final g in l.goals) _scaled(g, factor)],
      stars: l.stars,
      seed: l.seed,
      conveyors: l.conveyors,
    );

LevelGoal _scaled(LevelGoal g, double f) => switch (g.type) {
      GoalType.collect =>
        LevelGoal.collect(g.piece!, max(8, (g.count * f).round())),
      GoalType.score =>
        LevelGoal.score(max(1500, (g.count * f / 100).round() * 100)),
      GoalType.clearNori => g,
    };

int _quantile(List<int> sorted, double q) =>
    sorted[((sorted.length - 1) * q.clamp(0.0, 1.0)).round()];

int _round100(int n) => (n / 100).round() * 100;

void main(List<String> args) {
  final nums = args.where((a) => !a.startsWith('-')).map(int.parse).toList();
  final runs = nums.isNotEmpty ? nums.first : 150;
  final only = nums.skip(1).toSet();
  final write = args.contains('--write');
  final files = Directory('assets/levels')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final f in files) {
    final text = f.readAsStringSync();
    final base = LevelConfig.fromJson(jsonDecode(text) as Map<String, dynamic>);
    if (only.isNotEmpty && !only.contains(base.id)) continue;
    final t = (base.id.clamp(1, 20) - 1) / 19;
    // Past level 21 the curve flattens (68% -> 60%); every 5th level is a
    // hard one and every 15th a boss (GDD sawtooth).
    final late = base.id > 21 ? (base.id - 21) / 29 : 0.0;
    final dip = base.id % 15 == 0
        ? 0.18
        : base.id % 5 == 0
            ? 0.12
            : 0.0;
    final targetWin = base.id == 21
        ? 0.66
        : base.id > 21
            ? _lerp(0.66, 0.58, late) - dip
            : _lerp(0.98, 0.68, t);
    final target3 =
        base.id > 20 ? _lerp(0.15, 0.10, late) : _lerp(0.50, 0.15, t);

    // Moves follow a gentle schedule; goal sizes are scaled (binary search,
    // never beyond x1.5 so early levels stay friendly) until the bot wins at
    // the target rate. Levels with nori keep their layout and tune moves.
    final scheduled = (20 + (base.id - 1) * 0.5).round();
    final fixedGoals = base.goals.every((g) => g.type == GoalType.clearNori);
    var moves = scheduled;
    var factor = 1.0;
    List<int> run() {
      final level = _variant(base, moves, factor);
      final wins = <int>[];
      for (var i = 0; i < runs; i++) {
        final r = play(level, _tuneSeed + i, greedy);
        if (r.won) wins.add(r.score);
      }
      return wins;
    }

    var scores = <int>[];
    if (fixedGoals) {
      for (moves = scheduled; moves < scheduled + 12; moves++) {
        scores = run();
        if (scores.length / runs >= targetWin) break;
      }
    } else {
      var lo = base.nori.any((n) => n > 0) ? 0.8 : 0.4, hi = 1.5;
      factor = hi;
      scores = run();
      // Still too easy at the largest goals: take moves away.
      while (scores.length / runs > targetWin + 0.08 && moves > 14) {
        moves--;
        scores = run();
      }
      if (scores.length / runs < targetWin) {
        for (var i = 0; i < 9; i++) {
          factor = (lo + hi) / 2;
          scores = run();
          if (scores.length / runs >= targetWin) {
            lo = factor;
          } else {
            hi = factor;
          }
        }
        factor = lo;
      }
      scores = run();
      // Nori levels can be too hard even with small goals: grant moves.
      while (
          scores.length / runs < targetWin - 0.04 && moves < scheduled + 10) {
        moves++;
        scores = run();
      }
    }
    final win = scores.length / runs;
    final tuned = _variant(base, moves, factor);
    scores.sort();
    // Share of winners that should earn 3 / 2+ stars.
    final q3 = (target3 / win).clamp(0.05, 0.9);
    final q2 = (q3 + 0.30).clamp(0.1, 0.95);
    final s1 = _round100(_quantile(scores, 0.05));
    var s2 = _round100(_quantile(scores, 1 - q2));
    var s3 = _round100(_quantile(scores, 1 - q3));
    if (s2 <= s1) s2 = s1 + 100;
    if (s3 <= s2) s3 = s2 + 100;
    String goalsOf(LevelConfig l) => l.goals
        .map((g) => '${g.piece?.name ?? g.type.name}:${g.count}')
        .join(' ');
    print('L${base.id}: moves ${base.moves}->$moves | ${goalsOf(base)} -> '
        '${goalsOf(tuned)} | win ${(win * 100).round()}% '
        '(target ${(targetWin * 100).round()}%) stars [$s1, $s2, $s3]');

    if (write) {
      var out = text.replaceFirst(RegExp(r'"moves":\s*\d+'), '"moves": $moves');
      final counts = [
        for (final g in tuned.goals)
          if (g.type != GoalType.clearNori) g.count,
      ];
      var k = 0;
      out = out.replaceAllMapped(
          RegExp(r'("type":\s*"(?:collect|score)"[^}]*?"count":\s*)\d+'),
          (m) => '${m[1]}${counts[k++]}');
      out = out.replaceFirst(
          RegExp(r'"stars":\s*\[[^\]]*\]'), '"stars": [$s1, $s2, $s3]');
      f.writeAsStringSync(out);
    }
  }
}
