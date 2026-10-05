import 'package:bsharp/data/providers/mobireg/parsers/bell_slots.dart';
import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/mobireg/fixtures.dart';

void main() {
  var nextId = 0;

  List<ResolvedEvent> repeated(String start, String end, int count) => [
    for (var i = 0; i < count; i++)
      ResolvedEvent(
        id: nextId++,
        date: DateTime(2026, 9, 7).add(Duration(days: i)),
        number: 0,
        startTime: start,
        endTime: end,
      ),
  ];

  ResolvedEvent eventFromTimes(Map<String, dynamic> json) {
    final from = json['dateTimeFrom'] as String;
    final to = json['dateTimeTo'] as String;
    return ResolvedEvent(
      id: json['id'] as int,
      date: DateTime.parse(from.substring(0, 10)),
      number: 0,
      startTime: from.substring(11, 16),
      endTime: to.substring(11, 16),
    );
  }

  group('deriveBellSlots', () {
    test('finds the eight bell slots of the real term', () {
      final events = [
        for (final json
            in loadMobiregFixture('timetable_term_times') as List<dynamic>)
          eventFromTimes(json as Map<String, dynamic>),
      ];

      expect(deriveBellSlots(events), {
        '08:00': 1,
        '08:50': 2,
        '09:45': 3,
        '10:40': 4,
        '11:30': 5,
        '12:30': 6,
        '13:30': 7,
        '14:25': 8,
      });
    });

    test('returns no slots for no events', () {
      expect(deriveBellSlots(const []), isEmpty);
    });

    test('ignores lessons that are not 45 minutes long', () {
      final events = repeated('09:00', '11:15', 10);

      expect(deriveBellSlots(events), isEmpty);
    });

    test('ignores a 45 minute time seen fewer than three times', () {
      final events = repeated('08:00', '08:45', 2);

      expect(deriveBellSlots(events), isEmpty);
    });

    test('keeps the more frequent of two overlapping slots', () {
      final events = [
        ...repeated('13:55', '14:40', 5),
        ...repeated('14:25', '15:10', 9),
      ];

      expect(deriveBellSlots(events), {'14:25': 1});
    });

    test('lets the earlier start win a tie in count', () {
      final events = [
        ...repeated('14:25', '15:10', 4),
        ...repeated('13:55', '14:40', 4),
      ];

      expect(deriveBellSlots(events), {'13:55': 1});
    });

    test('accepts times with seconds', () {
      final events = repeated('08:00:00', '08:45:00', 3);

      expect(deriveBellSlots(events), {'08:00': 1});
    });
  });

  group('assignBellSlotNumbers', () {
    test('numbers events by their start and leaves off-slot ones at 0', () {
      final events = [
        ...repeated('08:00', '08:45', 3),
        ...repeated('08:50', '09:35', 3),
        ...repeated('08:50', '10:20', 1),
        ...repeated('17:00', '18:30', 1),
      ];

      final numbered = assignBellSlotNumbers(events);

      expect(numbered.map((e) => e.number), [1, 1, 1, 2, 2, 2, 2, 0]);
    });

    test('keeps the order of the events', () {
      final events = repeated('08:00', '08:45', 3);

      final numbered = assignBellSlotNumbers(events);

      expect(numbered.map((e) => e.id), events.map((e) => e.id));
    });
  });
}
