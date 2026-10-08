import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/event.dart';
import '../core/level_tuning.dart';
import '../gen/assets.gen.dart';

/// Where the event schedule comes from. The app ships [AssetEventSource]; a
/// Remote Config source can replace it later without touching anything else.
abstract interface class EventConfigSource {
  Future<EventSchedule> load();
}

/// The schedule bundled in `assets/events/events.json`.
class AssetEventSource implements EventConfigSource {
  AssetEventSource([String? path]) : path = path ?? Assets.events.events;
  final String path;

  @override
  Future<EventSchedule> load() async =>
      EventSchedule.parse(await rootBundle.loadString(path));
}

/// Overridden in `main` once the schedule is loaded, and in tests. No events
/// by default.
final eventScheduleProvider =
    Provider<EventSchedule>((ref) => EventSchedule.empty);

/// Remote difficulty overrides. None by default; `main` overrides it from
/// Remote Config.
final levelTuningProvider = Provider<LevelTuning>((ref) => LevelTuning.none);
