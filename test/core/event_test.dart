import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/core/event.dart';
import 'package:sushi_trio/core/piece.dart';

const _raw = '''
{
  "anchor": "2026-10-05",
  "events": [
    {"id": "salmon", "kind": "salmon", "title": {"en": "Salmon Week"},
     "milestones": [{"target": 10, "coins": 5}, {"target": 20, "coins": 9}]},
    {"id": "maguro", "kind": "maguro", "title": {"en": "Maguro Week"},
     "milestones": [{"target": 10, "coins": 5}]},
    {"id": "bad", "kind": "nope", "title": {"en": "x"},
     "milestones": [{"target": 10, "coins": 5}]},
    {"id": "unsorted", "kind": "ebi", "title": {"en": "x"},
     "milestones": [{"target": 10, "coins": 5}, {"target": 5, "coins": 5}]}
  ]
}
''';

void main() {
  final schedule = EventSchedule.parse(_raw);

  test('bad entries are skipped, the rest parse', () {
    expect(schedule.events.map((e) => e.id), ['salmon', 'maguro']);
    expect(schedule.events.first.kind, PieceKind.salmon);
    expect(schedule.events.first.goal, 20);
  });

  test('bad JSON gives the fallback', () {
    expect(EventSchedule.parse('{nope').events, isEmpty);
    expect(EventSchedule.parse('{"events": 3}').events, isEmpty);
  });

  test('rotation changes event every week and ids differ per week', () {
    final w0 = schedule.activeAt(DateTime(2026, 10, 7, 12))!;
    expect(w0.kind, PieceKind.salmon);
    expect(w0.id, 'salmon@0');
    expect(w0.start, DateTime(2026, 10, 5));
    expect(w0.end, DateTime(2026, 10, 12));

    expect(schedule.activeAt(DateTime(2026, 10, 11, 23, 59))!.id, 'salmon@0');
    expect(schedule.activeAt(DateTime(2026, 10, 12))!.id, 'maguro@1');
    // Wraps around after the last template, with a fresh id.
    expect(schedule.activeAt(DateTime(2026, 10, 19))!.id, 'salmon@2');
    expect(schedule.activeAt(DateTime(2026, 10, 4)), isNull);
  });

  test('a dated event wins over the rotation while it runs', () {
    final s = EventSchedule(anchor: schedule.anchor, events: [
      ...schedule.events,
      EventConfig(
        id: 'special',
        kind: PieceKind.ikura,
        titles: const {'en': 'Special'},
        milestones: const [EventMilestone(5, 1)],
        start: DateTime(2026, 10, 8),
        end: DateTime(2026, 10, 10),
      ),
    ]);
    expect(s.activeAt(DateTime(2026, 10, 7))!.id, 'salmon@0');
    expect(s.activeAt(DateTime(2026, 10, 8))!.id, 'special');
    expect(s.activeAt(DateTime(2026, 10, 10))!.id, 'salmon@0');
  });

  test('milestone helpers and time left', () {
    final e = schedule.activeAt(DateTime(2026, 10, 7))!;
    expect(e.nextMilestone(0), 0);
    expect(e.nextMilestone(10), 1);
    expect(e.nextMilestone(20), isNull);
    expect(e.timeLeft(DateTime(2026, 10, 11)), const Duration(days: 1));
    expect(e.timeLeft(DateTime(2026, 10, 13)), Duration.zero);
  });
}
