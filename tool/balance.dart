// ignore_for_file: avoid_print
// Balancing report: plays every level with two simple strategies over many
// seeds and prints win rate and star spread.
//
//   dart run tool/balance.dart [runs=200] [level ...]
import 'dart:convert';
import 'dart:io';

import 'dart:math';

import 'package:sushi_match/core/game_engine.dart';
import 'package:sushi_match/core/level.dart';

import 'bots.dart';

void main(List<String> args) {
  final runs = args.isNotEmpty ? int.parse(args.first) : 200;
  final only = args.skip(1).map(int.parse).toSet();
  final files = Directory('assets/levels')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  print('lvl  moves | random win  ★1  ★2  ★3 | greedy win  ★1  ★2  ★3');
  for (final f in files) {
    final level = LevelConfig.fromJson(
        jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
    if (only.isNotEmpty && !only.contains(level.id)) continue;
    String row(Move Function(GameEngine, Random) bot) {
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

    print('${level.id.toString().padLeft(3)}  ${level.moves.toString().padLeft(5)} | '
        '${row(random)} | ${row(greedy)}');
  }
}
