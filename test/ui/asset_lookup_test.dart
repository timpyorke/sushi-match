import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/core/piece.dart';
import 'package:sushi_trio/game/piece_painter.dart';
import 'package:sushi_trio/services/restaurant.dart';
import 'package:sushi_trio/ui/ui_art.dart';

void main() {
  bool exists(String path) => File(path).existsSync();

  test('every region has a banner icon', () {
    for (final s in Restaurant.shops) {
      expect(exists(UiArt.shop(s.id).path), isTrue, reason: s.id);
    }
  });

  test('every furniture piece has a sprite', () {
    for (final f in Restaurant.furniture) {
      expect(exists(UiArt.furniture(f.id).path), isTrue, reason: f.id);
    }
  });

  test('every obstacle used by goals and tips has an icon', () {
    for (final id in [
      'nori', 'ice', 'bag', 'deliver', 'mat', 'fire', 'cat', //
      'conveyor', 'key', 'bomb', 'portal', 'gravity',
    ]) {
      expect(exists(UiArt.obstacle(id).path), isTrue, reason: id);
    }
  });

  test('unknown ids fail loudly', () {
    expect(() => UiArt.shop('atlantis'), throwsArgumentError);
  });

  test('every piece kind has a sushi sprite', () {
    for (final kind in PieceKind.values.take(PiecePainter.spriteKinds)) {
      expect(exists(PiecePainter.spriteOf(kind).path), isTrue,
          reason: kind.name);
    }
  });
}
