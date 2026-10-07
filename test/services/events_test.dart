import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/core/event.dart';
import 'package:sushi_trio/core/settings.dart';
import 'package:sushi_trio/services/event_config.dart';
import 'package:sushi_trio/services/events.dart';
import 'package:sushi_trio/services/store.dart';
import 'package:sushi_trio/services/wallet.dart';

const _raw = '''
{
  "anchor": "2026-10-05",
  "events": [
    {"id": "salmon", "kind": "salmon", "title": {"en": "Salmon Week"},
     "milestones": [
       {"target": 10, "coins": 5},
       {"target": 20, "coins": 0, "booster": "chopsticks", "qty": 2}]},
    {"id": "maguro", "kind": "maguro", "title": {"en": "Maguro Week"},
     "milestones": [{"target": 10, "coins": 5}]}
  ]
}
''';

ProviderContainer _container(Store store, DateTime Function() clock) {
  final c = ProviderContainer(overrides: [
    storeProvider.overrideWithValue(store),
    clockProvider.overrideWithValue(clock),
    eventScheduleProvider.overrideWithValue(EventSchedule.parse(_raw)),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  var now = DateTime(2026, 10, 7, 9);
  late MemoryStore store;
  late ProviderContainer c;

  setUp(() {
    now = DateTime(2026, 10, 7, 9);
    store = MemoryStore();
    c = _container(store, () => now);
  });

  test('collecting climbs the tally; milestones unlock at their target', () {
    final e = c.read(eventProvider.notifier);
    expect(c.read(eventProvider).active!.id, 'salmon@0');
    e.addCollected(9);
    expect(c.read(eventProvider).canClaim(0), isFalse);
    e.addCollected(1);
    expect(c.read(eventProvider).canClaim(0), isTrue);
    expect(c.read(eventProvider).claimable, 1);
  });

  test('claim pays coins and boosters once', () {
    final e = c.read(eventProvider.notifier);
    e.addCollected(25);
    expect(e.claim(0)!.coins, 5);
    expect(c.read(walletProvider).coins, Wallet.startingCoins + 5);
    expect(e.claim(0), isNull);
    expect(e.claim(2), isNull);

    e.claim(1);
    expect(c.read(walletProvider).count(Booster.chopsticks), 2);
    expect(c.read(eventProvider).claimable, 0);
  });

  test('progress survives a restart', () {
    final e = c.read(eventProvider.notifier);
    e.addCollected(12);
    e.claim(0);

    final again = _container(store, () => now);
    expect(again.read(eventProvider).collected, 12);
    expect(again.read(eventProvider).claimed, {0});
  });

  test('a new week starts from zero, even while the app stays open', () {
    final e = c.read(eventProvider.notifier);
    e.addCollected(12);

    now = DateTime(2026, 10, 12, 8);
    e.addCollected(3);
    final s = c.read(eventProvider);
    expect(s.active!.id, 'maguro@1');
    expect(s.collected, 3);
    expect(s.claimed, isEmpty);
  });

  test('nothing counts when no event is running', () {
    now = DateTime(2026, 10, 1);
    final e = _container(store, () => now).read(eventProvider.notifier);
    e.addCollected(50);
    expect(e.state.active, isNull);
    expect(e.state.collected, 0);
  });

  test('start popup shows once per event', () {
    final e = c.read(eventProvider.notifier);
    expect(e.unseen, isTrue);
    e.markSeen();
    expect(e.unseen, isFalse);
    now = DateTime(2026, 10, 12);
    e.refresh();
    expect(c.read(eventProvider.notifier).unseen, isTrue);
  });

  test('reset clears the tally', () {
    final e = c.read(eventProvider.notifier);
    e.addCollected(15);
    e.reset();
    expect(c.read(eventProvider).collected, 0);
  });

  test('test mode forces an event outside its dates', () {
    now = DateTime(2026, 10, 1);
    final t = _container(store, () => now);
    expect(t.read(eventProvider).active, isNull);
    t.read(settingsProvider.notifier).setTestMode(true);
    expect(t.read(eventProvider).active, isNotNull);
  });
}
