import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sushi_match/core/settings.dart';
import 'package:sushi_match/services/tips.dart';
import 'package:sushi_match/ui/l10n.dart';
import 'package:sushi_match/ui/tip_overlay.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Settings.language.value = 'en';
    await Tips.load();
  });

  testWidgets('shows once, blocks taps, then is remembered', (tester) async {
    var behindTaps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(children: [
          GestureDetector(onTap: () => behindTaps++),
          const TipOverlay(id: 'conveyor', emoji: '➡️', text: 'tipConveyor'),
        ]),
      ),
    ));
    expect(find.text(L10n.t('tipConveyorTitle')), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    expect(behindTaps, 0, reason: 'overlay must swallow taps');

    await tester.tap(find.text('Got it!'));
    await tester.pump();
    expect(find.text(L10n.t('tipConveyorTitle')), findsNothing);
    expect(Tips.isSeen('conveyor'), isTrue);

    // Survives a reload.
    await Tips.load();
    expect(Tips.isSeen('conveyor'), isTrue);
    await Tips.reset();
    expect(Tips.isSeen('conveyor'), isFalse);
  });
}
