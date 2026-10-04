import 'package:bsharp/data/providers/mobireg/parsers/json_fields.dart';
import 'package:bsharp/data/services/mobireg_translations.dart';
import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:flutter/foundation.dart';

const _statsView = 'attendance-stats';
const _timetableView = 'timetable-events';
const _firstTypeId = 1;
const _unknownCountAs = '';

@immutable
class ParsedAttendance {
  const ParsedAttendance({required this.attendances, required this.types});

  final List<Attendance> attendances;
  final List<AttendanceType> types;
}

@immutable
class _RawType {
  const _RawType({
    required this.label,
    required this.abbr,
    required this.countAs,
  });

  final String label;
  final String abbr;
  final String countAs;
}

ParsedAttendance parseAttendance({
  required Object timetableEvents,
  required Object attendanceStats,
  required int pupilId,
}) {
  if (attendanceStats is! Map<String, dynamic>) {
    throw FormatException(
      'View $_statsView: expected an object',
      attendanceStats,
    );
  }
  final rawTypes = <String, _RawType>{};
  for (final record in objectsOf(attendanceStats['records'], _statsView)) {
    final label = stringField(record, 'tn', _statsView);
    rawTypes[label] = _RawType(
      label: label,
      abbr: stringField(record, 'ab', _statsView),
      countAs: stringField(record, 'ca', _statsView),
    );
  }
  final events = objectsOf(timetableEvents, _timetableView);
  for (final event in events) {
    final label = optionalStringField(event, 'attendanceLabel');
    if (label != null) {
      rawTypes.putIfAbsent(
        label,
        () => _RawType(label: label, abbr: label, countAs: _unknownCountAs),
      );
    }
  }
  final labels = rawTypes.keys.toList()..sort();
  final typeIds = {
    for (final (index, label) in labels.indexed) label: index + _firstTypeId,
  };
  final types = [
    for (final label in labels) _typeOf(typeIds[label]!, rawTypes[label]!),
  ];
  final attendances = [
    for (final event in events)
      if (optionalStringField(event, 'attendanceLabel') case final label?)
        Attendance(
          id: intField(event, 'id', _timetableView),
          eventsId: intField(event, 'id', _timetableView),
          studentsId: pupilId,
          typesId: typeIds[label]!,
        ),
  ];
  return ParsedAttendance(attendances: attendances, types: types);
}

AttendanceType _typeOf(int id, _RawType raw) {
  final countAs = AttendanceCountAs.fromString(raw.countAs);
  return AttendanceType(
    id: id,
    name: normalizeMobiregAttendanceName(raw.label),
    abbr: normalizeMobiregAttendanceAbbr(raw.abbr),
    countAs: countAs,
    excuseStatus: _excuseStatusOf(raw.label, countAs),
  );
}

AttendanceExcuseStatus _excuseStatusOf(
  String label,
  AttendanceCountAs countAs,
) {
  final name = label.toLowerCase();
  if (name.contains('nieusprawiedliwion')) {
    return AttendanceExcuseStatus.unexcused;
  }
  if (name.contains('usprawiedliwion')) {
    return AttendanceExcuseStatus.excused;
  }
  final isMissed =
      countAs == AttendanceCountAs.absent || countAs == AttendanceCountAs.late;
  if (isMissed &&
      (name.startsWith('nieobecność') || name.startsWith('spóźnienie'))) {
    return AttendanceExcuseStatus.unexcused;
  }
  return AttendanceExcuseStatus.unset;
}
