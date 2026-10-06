import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/core/game_engine.dart';
import 'package:sushi_trio/core/level.dart';
import 'package:sushi_trio/core/move_finder.dart';

void main() {
  test('every level file parses and its goals are reachable', () {
    final files = Directory('assets/levels')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    expect(files.length, 60);
    for (final f in files) {
      final level = LevelConfig.fromJson(
          jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
      final n = int.parse(RegExp(r'(\d+)\.json').firstMatch(f.path)!.group(1)!);
      expect(level.id, n, reason: f.path);
      for (final g in level.goals.where((g) => g.piece != null)) {
        expect(level.pieces, contains(g.piece), reason: f.path);
      }
    }
  });

  test('bag, portal and sideways-gravity levels never leave an open cell empty',
      () {
    final files = Directory('assets/levels')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'));
    var checked = 0;
    for (final f in files) {
      final level = LevelConfig.fromJson(
          jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
      // Spreading mats may legitimately starve a sealed pocket.
      final tricky = level.bags.any((n) => n > 0) ||
          level.portals.isNotEmpty ||
          level.gravity != Gravity.down;
      if (!tricky || level.mats.any((m) => m)) continue;
      checked++;
      for (var seed = 0; seed < 3; seed++) {
        final e = GameEngine(level, seed: seed);
        final rng = Random(seed);
        for (var i = 0; i < 40 && e.status == GameStatus.playing; i++) {
          final moves = MoveFinder.allMoves(e.board);
          final m = moves[rng.nextInt(moves.length)];
          e.trySwap(m.$1, m.$2);
          for (final p in e.board.positions) {
            expect(e.board[p], isNotNull,
                reason: 'level ${level.id} seed $seed hole at $p');
          }
        }
      }
    }
    expect(checked, greaterThan(0));
  });
}
