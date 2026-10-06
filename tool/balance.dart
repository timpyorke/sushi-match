// ignore_for_file: avoid_print
// Balancing report: plays every level with two simple strategies over many
// seeds and prints win rate and star spread.
//
//   dart run tool/balance.dart [runs=200] [level ...] [--planner] [--no-belts]
//
// --planner  add the lookahead bot (slow; pick levels to limit run time)
// --no-belts also play each conveyor level with its belts removed, to show
//            how much the belts change the difficulty
import 'dart:convert';
import 'dart:io';

import 'dart:math';

import 'package:sushi_match/core/game_engine.dart';
import 'package:sushi_match/core/level.dart';

import 'bots.dart';

LevelConfig _withoutBelts(LevelConfig l) => LevelConfig(
      id: l.id,
      rows: l.rows,
      cols: l.cols,
      playable: l.playable,
      nori: l.nori,
      ice: l.ice,
      bags: l.bags,
      pieces: l.pieces,
      moves: l.moves,
      goals: l.goals,
      stars: l.stars,
      seed: l.seed,
    );

void main(List<String> args) {
  final nums = args.where((a) => !a.startsWith('-')).map(int.parse).toList();
  final runs = nums.isNotEmpty ? nums.first : 200;
  final only = nums.skip(1).toSet();
  final withPlanner = args.contains('--planner');
  final noBelts = args.contains('--no-belts');
  final files = Directory('assets/levels')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  String row(LevelConfig level, Move Function(GameEngine, Random) bot) {
    var wins = 0;
    final stars = [0, 0, 0, 0];
    for (var i = 0; i < runs; i++) {
      final res = play(level, 5000 + i, bot);
      if (res.won) {
        wins++;
        stars[res.stars]++;
      }
    }
    String pct(int n) => '${(100 * n / runs).round()}%'.padLeft(4);
    return '${pct(wins)} ${pct(stars[1])} ${pct(stars[2])} ${pct(stars[3])}';
  }

  print('lvl  moves | random win  ★1  ★2  ★3 | greedy win  ★1  ★2  ★3'
      '${withPlanner ? ' | planner win  ★1  ★2  ★3' : ''}');
  for (final f in files) {
    final level = LevelConfig.fromJson(
        jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
    if (only.isNotEmpty && !only.contains(level.id)) continue;
    String line(LevelConfig l) => '${row(l, random)} | ${row(l, greedy)}'
        '${withPlanner ? ' | ${row(l, planner)}' : ''}';
    final head = '${level.id.toString().padLeft(3)}  '
        '${level.moves.toString().padLeft(5)} | ';
    print('$head${line(level)}');
    if (noBelts && level.conveyors.isNotEmpty) {
      print('  (no belts)  | ${line(_withoutBelts(level))}');
    }
  }
}
