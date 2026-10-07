import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/core/settings.dart';
import 'package:sushi_trio/ui/l10n.dart';
import 'package:sushi_trio/ui/settings_screen.dart';

import '../helpers/riverpod.dart';

void main() {
  testWidgets('volume sliders and one language radio per language',
      (tester) async {
    final c = testContainer();
    await tester
        .pumpWidget(scope(c, const MaterialApp(home: SettingsScreen())));

    expect(find.byType(Slider), findsNWidgets(2));
    expect(find.byType(RadioListTile<String>),
        findsNWidgets(L10n.languages.length));

    await tester.drag(find.byType(Slider).first, const Offset(-1000, 0));
    await tester.pump();
    expect(c.read(settingsProvider).soundVolume, 0);
    expect(find.byIcon(Icons.volume_off), findsOneWidget);

    await tester.tap(find.text(L10n.languages['th']!));
    await tester.pump();
    expect(c.read(settingsProvider).language, 'th');
    expect(L10n.language, 'th');
  });
}
