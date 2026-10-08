import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('every bundled image decodes and none is left as PNG',
      (tester) async {
    final files = [
      for (final dir in ['assets/ui', 'assets/sprites', 'assets/backgrounds'])
        for (final f in Directory(dir).listSync(recursive: true))
          if (f is File && !f.path.replaceAll(r'\', '/').contains('/source/'))
            f,
    ];
    expect(files, isNotEmpty);
    final bad = <String>[];
    await tester.runAsync(() async {
      for (final f in files.where((f) => f.path.endsWith('.webp'))) {
        try {
          final codec = await ui.instantiateImageCodec(f.readAsBytesSync());
          final frame = await codec.getNextFrame();
          if (frame.image.width == 0) bad.add(f.path);
          frame.image.dispose();
          codec.dispose();
        } catch (e) {
          bad.add('${f.path}: $e');
        }
      }
    });
    expect(bad, isEmpty);
    expect(files.where((f) => f.path.endsWith('.png')), isEmpty,
        reason: 'run tool/to_webp.sh');
  });
}
