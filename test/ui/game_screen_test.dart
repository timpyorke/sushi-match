import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sushi_match/main.dart';
import 'package:sushi_match/services/tips.dart';
import 'package:sushi_match/services/wallet.dart';

void main() {
  testWidgets('a level has a shop button that fits a narrow phone',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Wallet.load();
    await Tips.load();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester
        .pumpWidget(const MaterialApp(home: GameScreen(levelNumber: 1)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('🛒'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
