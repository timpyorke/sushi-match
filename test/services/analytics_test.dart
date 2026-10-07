import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/game/sushi_game.dart';
import 'package:sushi_trio/services/analytics.dart';
import 'package:sushi_trio/services/wallet.dart';

import '../core/helpers.dart';
import '../helpers/riverpod.dart';

class _Recorder implements AnalyticsSink {
  final events = <(String, Map<String, Object>)>[];
  @override
  void log(String name, Map<String, Object> params) =>
      events.add((name, params));
}

void main() {
  test('level_start carries the level and counts attempts per session', () {
    final rec = _Recorder();
    final analytics = Analytics(rec);
    final c = testContainer();
    final level = testLevel();
    SushiGame(
        level: level,
        wallet: c.read(walletProvider.notifier),
        analytics: analytics);
    SushiGame(
        level: level,
        wallet: c.read(walletProvider.notifier),
        analytics: analytics);
    expect(rec.events.map((e) => e.$1),
        [AnalyticsEvent.levelStart, AnalyticsEvent.levelStart]);
    expect(rec.events.map((e) => e.$2['attempt_no']), [1, 2]);
    expect(rec.events.first.$2['level_id'], level.id);
  });

  test('no sink means no events and no crash', () {
    final c = testContainer();
    SushiGame(level: testLevel(), wallet: c.read(walletProvider.notifier));
    Analytics().log('x');
  });
}
