import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/core/event.dart';
import 'package:sushi_trio/services/event_config.dart';
import 'package:sushi_trio/services/events.dart';
import 'package:sushi_trio/services/store.dart';
import 'package:sushi_trio/services/wallet.dart';
import 'package:sushi_trio/ui/event_banner.dart';
import 'package:sushi_trio/ui/event_dialog.dart';
import 'package:sushi_trio/ui/l10n.dart';
import 'package:sushi_trio/ui/ui_art.dart';

const _raw = '''
{"anchor": "2026-10-05", "events": [
  {"id": "salmon", "kind": "salmon", "title": {"en": "Salmon Week"},
   "milestones": [{"target": 10, "coins": 5}]}]}
''';

ProviderContainer _container(EventSchedule schedule) {
  L10n.language = 'en';
  final c = ProviderContainer(overrides: [
    storeProvider.overrideWithValue(MemoryStore()),
    clockProvider.overrideWithValue(() => DateTime(2026, 10, 7, 9)),
    eventScheduleProvider.overrideWithValue(schedule),
  ]);
  addTearDown(c.dispose);
  return c;
}

Widget _app(ProviderContainer c, Widget child) => UncontrolledProviderScope(
    container: c, child: MaterialApp(home: Scaffold(body: child)));

void main() {
  testWidgets('banner is hidden when no event is running', (tester) async {
    final c = _container(EventSchedule.empty);
    await tester.pumpWidget(_app(c, const EventBanner()));
    expect(find.text('Salmon Week'), findsNothing);
  });

  testWidgets('banner shows progress and the dialog claims a milestone',
      (tester) async {
    final c = _container(EventSchedule.parse(_raw));
    c.read(eventProvider.notifier).addCollected(10);
    await tester.pumpWidget(_app(c, const EventBanner()));
    expect(find.text('Salmon Week'), findsOneWidget);
    expect(find.textContaining('10/10'), findsOneWidget);

    await tester.tap(find.byType(EventBanner));
    await tester.pumpAndSettle();
    expect(find.byType(EventDialog), findsOneWidget);

    await tester.tap(find.text('Claim'));
    await tester.pumpAndSettle();
    expect(c.read(walletProvider).coins, Wallet.startingCoins + 5);
    expect(find.byWidgetPredicate((w) => w is Image && w.image == UiArt.check),
        findsOneWidget);
  });
}
