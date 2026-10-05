import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/domain/schedule_utils.dart';

const _lessonLengthMinutes = 45;
const _minimumOccurrences = 3;
const _timeLength = 5;
const _firstLessonNumber = 1;
const _noLessonNumber = 0;

class _Candidate {
  const _Candidate({
    required this.start,
    required this.startMinutes,
    required this.endMinutes,
    required this.occurrences,
  });

  final String start;
  final int startMinutes;
  final int endMinutes;
  final int occurrences;

  bool overlaps(_Candidate other) =>
      startMinutes < other.endMinutes && other.startMinutes < endMinutes;
}

Map<String, int> deriveBellSlots(List<ResolvedEvent> events) {
  final chosen = <_Candidate>[];
  for (final candidate in _candidatesOf(events)) {
    if (!chosen.any(candidate.overlaps)) {
      chosen.add(candidate);
    }
  }
  chosen.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
  return {
    for (var i = 0; i < chosen.length; i++)
      chosen[i].start: _firstLessonNumber + i,
  };
}

List<ResolvedEvent> assignBellSlotNumbers(List<ResolvedEvent> events) {
  final slots = deriveBellSlots(events);
  return [
    for (final event in events)
      event.copyWith(
        number: slots[_shortTime(event.startTime)] ?? _noLessonNumber,
      ),
  ];
}

List<_Candidate> _candidatesOf(List<ResolvedEvent> events) {
  final counts = <(String, String), int>{};
  for (final event in events) {
    final key = (_shortTime(event.startTime), _shortTime(event.endTime));
    counts[key] = (counts[key] ?? 0) + 1;
  }
  final candidates = <_Candidate>[];
  for (final MapEntry(:key, :value) in counts.entries) {
    final startMinutes = parseTimeMinutes(key.$1);
    final endMinutes = parseTimeMinutes(key.$2);
    if (startMinutes == null || endMinutes == null) {
      throw FormatException('Unreadable lesson time ${key.$1}-${key.$2}');
    }
    if (endMinutes - startMinutes == _lessonLengthMinutes &&
        value >= _minimumOccurrences) {
      candidates.add(
        _Candidate(
          start: key.$1,
          startMinutes: startMinutes,
          endMinutes: endMinutes,
          occurrences: value,
        ),
      );
    }
  }
  return candidates..sort((a, b) {
    final byCount = b.occurrences.compareTo(a.occurrences);
    return byCount != 0 ? byCount : a.startMinutes.compareTo(b.startMinutes);
  });
}

String _shortTime(String time) => time.substring(0, _timeLength);
