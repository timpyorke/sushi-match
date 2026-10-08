import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/services/store.dart';
import 'package:sushi_trio/services/tips.dart';
import 'package:sushi_trio/ui/l10n.dart';
import 'package:sushi_trio/ui/tip_overlay.dart';

import '../helpers/riverpod.dart';

void main() {
  testWidgets('shows once, blocks taps, then is remembered', (tester) async {
    final store = MemoryStore();
    final c = testContainer(store: store);
    var behindTaps = 0;
    await tester.pumpWidget(scope(
        c,
        MaterialApp(
          home: Scaffold(
            body: Stack(children: [
              GestureDetector(onTap: () => behindTaps++),
              const TipOverlay(
                  id: 'conveyor',
                  iconAsset: 'assets/ui/obstacles/conveyor.png',
                  text: 'tipConveyor'),
            ]),
          ),
        )));
    expect(find.text(L10n.t('tipConveyorTitle')), findsWidgets);

    await tester.tapAt(const Offset(10, 10));
    expect(behindTaps, 0, reason: 'overlay must swallow taps');

    await tester.tap(find.text('Got it!'));
    await tester.pump();
    expect(find.text(L10n.t('tipConveyorTitle')), findsNothing);
    expect(c.read(tipsProvider), contains('conveyor'));

    // Survives a restart.
    expect(
        testContainer(store: store).read(tipsProvider), contains('conveyor'));
    c.read(tipsProvider.notifier).reset();
    expect(c.read(tipsProvider), isEmpty);
  });
}
