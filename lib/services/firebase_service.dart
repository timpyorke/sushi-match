import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../core/event.dart';
import '../core/level_tuning.dart';
import 'event_config.dart';

/// Remote Config key holding the event schedule JSON (same shape as
/// `assets/events/events.json`).
const eventScheduleKey = 'event_schedule';

/// Remote Config key holding the [LevelTuning] JSON.
const levelTuningKey = 'level_tuning';

/// Starts Firebase and routes uncaught errors to Crashlytics. Returns false
/// (and the game carries on offline) when Firebase isn't configured, e.g. a
/// checkout without `google-services.json` / `GoogleService-Info.plist`.
Future<bool> initFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase disabled: $e');
    return false;
  }
  // Crashlytics stays off in debug so dev crashes don't pollute reports.
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  return true;
}

/// One Remote Config fetch shared by everything that reads it. Null when
/// offline or unavailable, so callers fall back to their bundled defaults.
class RemoteConfigFetch {
  RemoteConfigFetch({FirebaseRemoteConfig? config}) : _config = config;

  final FirebaseRemoteConfig? _config;
  Future<FirebaseRemoteConfig?>? _fetch;

  Future<FirebaseRemoteConfig?> get config => _fetch ??= _run();

  Future<FirebaseRemoteConfig?> _run() async {
    try {
      final rc = _config ?? FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval:
            kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));
      await rc.fetchAndActivate();
      return rc;
    } catch (e) {
      debugPrint('Remote Config unavailable: $e');
      return null;
    }
  }
}

/// Event schedule from Remote Config, falling back to [fallback] (the bundled
/// asset schedule) when offline, unset or unparsable.
class RemoteConfigEventSource implements EventConfigSource {
  RemoteConfigEventSource(this.fallback, this.remote);

  final EventConfigSource fallback;
  final RemoteConfigFetch remote;

  @override
  Future<EventSchedule> load() async {
    final bundled = await fallback.load();
    final raw = (await remote.config)?.getString(eventScheduleKey) ?? '';
    return raw.isEmpty ? bundled : EventSchedule.parse(raw, fallback: bundled);
  }
}

/// Level difficulty overrides from Remote Config; [LevelTuning.none] when
/// offline or unset.
Future<LevelTuning> loadLevelTuning(RemoteConfigFetch remote) async {
  final raw = (await remote.config)?.getString(levelTuningKey) ?? '';
  return raw.isEmpty ? LevelTuning.none : LevelTuning.parse(raw);
}
