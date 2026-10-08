import 'dart:convert';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/core/game_engine.dart';
import 'package:sushi_trio/core/level.dart';
import 'package:sushi_trio/core/move_finder.dart';
import 'package:sushi_trio/core/pos.dart';
import 'package:sushi_trio/game/board_component.dart';
import 'package:sushi_trio/game/cat_component.dart';
import 'package:sushi_trio/game/obstacle_art.dart';
import 'package:sushi_trio/game/tile_art.dart';
import 'package:sushi_trio/services/wallet.dart';

LevelConfig _level(int n) => LevelConfig.fromJson(jsonDecode(
    File('assets/levels/level_${n.toString().padLeft(3, '0')}.json')
        .readAsStringSync()) as Map<String, dynamic>);

void main() {
  // Nori, ice, cats, deliveries, fire, bags + belts, mats + belts, gravity,
  // bombs + keys, cats + portals.
  for (final n in [11, 23, 22, 33, 27, 38, 41, 53, 55, 58]) {
    testWidgets('level $n: after each turn every view sits on its piece',
        (tester) async {
      final engine = GameEngine(_level(n), seed: 3);
      var turns = 0;
      final board = BoardComponent(
        engine: engine,
        onTurnFinished: () => turns++,
        onPraise: (_) {},
        armed: ValueNotifier<Booster?>(null),
        canSpendBooster: (_) => true,
        onSpendBooster: (_) => true,
      );
      // The art loads through real IO, which the fake clock never runs.
      await tester.runAsync(() async {
        await TileArt.load();
        await ObstacleArt.load();
        await CatArt.load();
      });
      await tester.pumpWidget(GameWidget(game: FlameGame(children: [board])));
      for (var i = 0; i < 10 && !board.isLoaded; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(board.isLoaded, isTrue);

      for (var turn = 1; turn <= 6; turn++) {
        if (engine.status != GameStatus.playing) break;
        final move = MoveFinder.findMove(engine.board);
        if (move == null) break;
        board.attempt(move.$1, move.$2);
        for (var i = 0; i < 2000 && turns < turn; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(turns, turn, reason: 'turn $turn did not finish');
        final expected = <Pos, int>{
          for (final p in engine.board.positions)
            if (engine.board[p] case final piece?) p: piece.id,
        };
        expect(board.viewIds, expected, reason: 'after turn $turn');
      }
      // Let the last pops and bursts run out.
      await tester.pump(const Duration(seconds: 2));
    });
  }
}
