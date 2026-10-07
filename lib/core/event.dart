import 'dart:convert';

import 'piece.dart';

/// One prize tier of a weekly event, paid once the cumulative tally reaches
/// [target].
class EventMilestone {
  const EventMilestone(this.target, this.coins, [this.booster, this.qty = 0]);

  final int target;
  final int coins;

  /// `Booster` enum name (resolved in `lib/services`; core stays free of the
  /// wallet).
  final String? booster;
  final int qty;

  factory EventMilestone.fromJson(Map<String, dynamic> j) => EventMilestone(
      j['target'] as int,
      j['coins'] as int? ?? 0,
      j['booster'] as String?,
      j['qty'] as int? ?? 0);
}

/// A weekly collection event ("Salmon Week"): clear [kind] pieces during
/// levels to climb the [milestones].
///
/// An event with [start] and [end] is dated and wins while it is running.
/// Undated events are templates that [EventSchedule] rotates through week by
/// week, so the bundled schedule never runs dry.
class EventConfig {
  const EventConfig({
    required this.id,
    required this.kind,
    required this.titles,
    required this.milestones,
    this.start,
    this.end,
  });

  final String id;
  final PieceKind kind;

  /// Language code to title; see [title].
  final Map<String, String> titles;
  final List<EventMilestone> milestones;
  final DateTime? start;
  final DateTime? end;

  String title(String language) => titles[language] ?? titles['en'] ?? id;

  int get goal => milestones.isEmpty ? 0 : milestones.last.target;

  bool isActiveAt(DateTime now) {
    final s = start, e = end;
    return s != null && e != null && !now.isBefore(s) && now.isBefore(e);
  }

  Duration timeLeft(DateTime now) {
    final e = end;
    return e == null || !now.isBefore(e) ? Duration.zero : e.difference(now);
  }

  /// Index of the first milestone not yet reached, or null when all are.
  int? nextMilestone(int collected) {
    for (var i = 0; i < milestones.length; i++) {
      if (collected < milestones[i].target) return i;
    }
    return null;
  }

  EventConfig windowed(String id, DateTime start, DateTime end) => EventConfig(
      id: id,
      kind: kind,
      titles: titles,
      milestones: milestones,
      start: start,
      end: end);

  /// Null when the entry is unusable (unknown sushi, no milestones...).
  static EventConfig? tryParse(Map<String, dynamic> j) {
    try {
      final kind = PieceKind.values.byName(j['kind'] as String);
      final milestones = [
        for (final m in j['milestones'] as List<dynamic>)
          EventMilestone.fromJson(m as Map<String, dynamic>)
      ];
      if (milestones.isEmpty) return null;
      for (var i = 0; i < milestones.length; i++) {
        if (milestones[i].target <= 0 ||
            (i > 0 && milestones[i].target <= milestones[i - 1].target)) {
          return null;
        }
      }
      final start = j['start'] as String?, end = j['end'] as String?;
      final s = start == null ? null : DateTime.parse(start);
      final e = end == null ? null : DateTime.parse(end);
      if ((s == null) != (e == null) || (s != null && !e!.isAfter(s))) {
        return null;
      }
      return EventConfig(
        id: j['id'] as String,
        kind: kind,
        titles: (j['title'] as Map<String, dynamic>).cast<String, String>(),
        milestones: milestones,
        start: s,
        end: e,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Which event is on right now.
class EventSchedule {
  const EventSchedule({this.anchor, this.events = const []});

  /// Start (a Monday, midnight) of rotation week 0.
  final DateTime? anchor;
  final List<EventConfig> events;

  static const empty = EventSchedule();

  /// Parses `{"anchor": "2026-10-05", "events": [...]}`. Never throws: bad
  /// entries are skipped, bad JSON gives [fallback].
  static EventSchedule parse(String raw,
      {EventSchedule fallback = EventSchedule.empty}) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final a = j['anchor'] as String?;
      return EventSchedule(
        anchor: a == null ? null : DateTime.parse(a),
        events: [
          for (final e in j['events'] as List<dynamic>)
            if (EventConfig.tryParse(e as Map<String, dynamic>) case final c?)
              c
        ],
      );
    } catch (_) {
      return fallback;
    }
  }

  /// The running event at [now]: a dated one first, else this week's turn of
  /// the rotation. Rotation week ids look like `salmon@3`, so progress starts
  /// over every week.
  EventConfig? activeAt(DateTime now) {
    for (final e in events) {
      if (e.isActiveAt(now)) return e;
    }
    final a = anchor;
    final templates = [
      for (final e in events)
        if (e.start == null) e
    ];
    if (a == null || templates.isEmpty || now.isBefore(a)) return null;
    final week = _calendarDays(a, now) ~/ 7;
    final from = DateTime(a.year, a.month, a.day + week * 7);
    final to = DateTime(a.year, a.month, a.day + week * 7 + 7);
    final t = templates[week % templates.length];
    return t.windowed('${t.id}@$week', from, to);
  }

  /// First event regardless of dates (the dev "test mode" shows it always).
  EventConfig? forced(DateTime now) {
    if (events.isEmpty) return null;
    final e = events.first;
    return e.windowed(e.id, DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 7));
  }

  // Whole calendar days; rounding keeps it DST-safe.
  static int _calendarDays(DateTime from, DateTime to) =>
      (DateTime(to.year, to.month, to.day)
                  .difference(DateTime(from.year, from.month, from.day))
                  .inHours /
              24)
          .round();
}
