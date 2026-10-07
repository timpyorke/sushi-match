import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/game/piece_painter.dart';

void main() {
  test('baked glow is a soft disc: solid centre, fading edge, clear corner',
      () async {
    const size = 100;
    final recorder = PictureRecorder();
    PiecePainter.glow(Canvas(recorder), const Offset(50, 50), 25,
        const Color(0xFFFF0000), 0.2);
    final image = await recorder.endRecording().toImage(size, size);
    final bytes = (await image.toByteData())!;
    int alpha(int x, int y) => bytes.getUint8((y * size + x) * 4 + 3);

    expect(alpha(50, 50), greaterThan(200));
    expect(alpha(50 + 25, 50), inInclusiveRange(40, 220));
    expect(alpha(2, 2), 0);
  });
}
