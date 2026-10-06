import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:sushi_trio/core/progress.dart';
import 'package:sushi_trio/core/settings.dart';
import 'package:sushi_trio/services/store.dart';
import 'package:sushi_trio/ui/l10n.dart';

import '../helpers/riverpod.dart';

void main() {
  test('HiveStore round-trips ints, strings and string lists', () async {
    final dir = Directory.systemTemp.createTempSync('sushi_hive_');
    Hive.init(dir.path);
    final box = await Hive.openBox<dynamic>('t');
    addTearDown(() async {
      await Hive.close();
      dir.deleteSync(recursive: true);
    });
    final store = HiveStore(box);
    await store.put('n', 3);
    await store.put('s', 'x');
    await store.put('l', ['a', 'b']);
    expect(store.get<int>('n'), 3);
    expect(store.get<String>('s'), 'x');
    expect(store.getStringList('l'), ['a', 'b']);
    expect(store.keys, containsAll(['n', 's', 'l']));
    await store.remove('n');
    expect(store.get<int>('n'), isNull);
  });

  test('settings persist and mirror into L10n and SettingsMirror', () {
    final store = MemoryStore();
    final c = testContainer(store: store);
    final s = c.read(settingsProvider.notifier);
    s.setLanguage('th');
    s.setColorblind(true);
    s.setHaptics(false);
    expect(L10n.language, 'th');
    expect(SettingsMirror.colorblind, isTrue);
    expect(SettingsMirror.haptics, isFalse);

    final again = testContainer(store: store).read(settingsProvider);
    expect(again.language, 'th');
    expect(again.colorblind, isTrue);
    expect(again.haptics, isFalse);
    expect(again.sound, isTrue);
  });

  test('progress only moves forward and resets', () {
    final store = MemoryStore();
    final c = testContainer(store: store);
    final p = c.read(progressProvider.notifier);
    p.markCleared(5);
    p.markCleared(3);
    expect(c.read(progressProvider), 5);
    expect(testContainer(store: store).read(progressProvider), 5);
    p.reset();
    expect(c.read(progressProvider), 0);
  });
}
