import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where analytics events go. Firebase in the app, a recorder in tests.
abstract interface class AnalyticsSink {
  void log(String name, Map<String, Object> params);
}

class FirebaseAnalyticsSink implements AnalyticsSink {
  @override
  void log(String name, Map<String, Object> params) {
    FirebaseAnalytics.instance
        .logEvent(name: name, parameters: params)
        .catchError((Object e) => debugPrint('Analytics error: $e'));
  }
}

/// Event names from the GDD (Analytics). `session_start` is not here: the
/// Firebase SDK logs it itself and the name is reserved.
abstract final class AnalyticsEvent {
  static const levelStart = 'level_start';
  static const levelWin = 'level_win';
  static const levelFail = 'level_fail';
  static const boosterUsed = 'booster_used';
  static const shuffleTriggered = 'shuffle_triggered';
}

class Analytics {
  Analytics([AnalyticsSink? sink]) : _sink = sink;

  final AnalyticsSink? _sink;
  final _attempts = <int, int>{};

  /// 1-based count of runs of [levelId] started this session.
  int nextAttempt(int levelId) =>
      _attempts[levelId] = (_attempts[levelId] ?? 0) + 1;

  void log(String name, [Map<String, Object> params = const {}]) =>
      _sink?.log(name, params);
}

/// Silent by default; `main` overrides it with the Firebase sink.
final analyticsProvider = Provider<Analytics>((ref) => Analytics());
