import 'dart:ui';

import 'package:bsharp/domain/entities/custom_event.dart';
import 'package:bsharp/domain/schedule_utils.dart';

sealed class TimelineItem {
  DateTime get date;
  String get startTime;
  String get endTime;
  String get displayTitle;
  String? get displaySubtitle;
  Color get displayColor;
  bool get isCancelled => false;
  bool get isSubstitution => false;
}

class LessonTimelineItem implements TimelineItem {
  LessonTimelineItem({required this.entry});

  final ScheduleEntry entry;

  @override
  bool get isCancelled => entry.isCancelled || entry.isReplaced;

  @override
  bool get isSubstitution =>
      entry.changeType == ScheduleChangeType.substitution;

  @override
  DateTime get date => entry.date;

  @override
  String get startTime => entry.startTime;

  @override
  String get endTime => entry.endTime;

  @override
  String get displayTitle => entry.subjectName ?? entry.eventName ?? '';

  @override
  String? get displaySubtitle {
    final parts = <String>[
      if (entry.teacherName != null) entry.teacherName!,
      if (entry.roomName != null) entry.roomName!,
    ];
    return parts.isEmpty ? null : parts.join(' • ');
  }

  @override
  Color get displayColor => entry.subjectName != null && entry.subjectId != null
      ? subjectColor(entry.subjectId!)
      : const Color(0xFF607D8B);
}

class CustomEventTimelineItem implements TimelineItem {
  CustomEventTimelineItem({required this.event, required this.occurrenceDate});

  final CustomEvent event;
  final DateTime occurrenceDate;

  @override
  bool get isCancelled => false;

  @override
  bool get isSubstitution => false;

  @override
  DateTime get date => occurrenceDate;

  @override
  String get startTime => event.startTime;

  @override
  String get endTime => event.endTime;

  @override
  String get displayTitle => event.title;

  @override
  String? get displaySubtitle => event.place;

  @override
  Color get displayColor => subjectColor(event.colorIndex);
}
