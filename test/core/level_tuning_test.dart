import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/core/level.dart';
import 'package:sushi_trio/core/level_tuning.dart';

void main() {
  final level = LevelConfig.fromJson(
      jsonDecode(File('assets/levels/level_001.json').readAsStringSync())
          as Map<String, dynamic>);

  test('moves sets, delta adds, level entry wins over *', () {
    expect(LevelTuning.parse('{"1":{"moves":40}}').apply(level).moves, 40);
    expect(LevelTuning.parse('{"1":{"moves_delta":3}}').apply(level).moves,
        level.moves + 3);
    expect(
        LevelTuning.parse('{"*":{"moves_delta":1},"1":{"moves":40}}')
            .apply(level)
            .moves,
        40);
  });

  test('floors at 1 and ignores other levels', () {
    expect(
        LevelTuning.parse('{"1":{"moves_delta":-999}}').apply(level).moves, 1);
    expect(LevelTuning.parse('{"2":{"moves":5}}').apply(level), same(level));
  });

  test('malformed input changes nothing', () {
    expect(LevelTuning.parse('not json').apply(level), same(level));
    expect(LevelTuning.parse('[1]').apply(level), same(level));
  });
}
