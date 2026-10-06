import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_match/core/level.dart';

void main() {
  test('every level file parses and its goals are reachable', () {
    final files = Directory('assets/levels')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    expect(files.length, 21);
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
}
