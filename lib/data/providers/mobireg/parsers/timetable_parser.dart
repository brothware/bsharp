import 'package:bsharp/data/providers/mobireg/parsers/json_fields.dart';
import 'package:bsharp/data/services/mobireg_translations.dart';
import 'package:bsharp/domain/entities/resolved_event.dart';

const _view = 'timetable-events';
const _dateLength = 10;
const _timeStart = 11;
const _timeEnd = 16;
const _noLessonNumber = 0;
const _flagSet = 1;
const _nameSeparator = ', ';

List<ResolvedEvent> parseTimetableEvents(
  Object data, {
  required Map<String, int> subjectIdsByName,
}) {
  return objectsOf(data, _view).map((json) {
    final from = stringField(json, 'dateTimeFrom', _view);
    final to = stringField(json, 'dateTimeTo', _view);
    final subjectName = normalizeMobiregSubjectName(
      stringField(json, 'subjectName', _view),
    );
    final relatedEventId = json['relatedEventId'];
    final isCancelled = json['isCanceled'] == _flagSet;
    final replacedByEventId = isCancelled && relatedEventId is int
        ? relatedEventId
        : null;
    final oldSubjectName = optionalStringField(json, 'oldSubjectName');
    return ResolvedEvent(
      id: intField(json, 'id', _view),
      date: DateTime.parse(from.substring(0, _dateLength)),
      number: _noLessonNumber,
      startTime: from.substring(_timeStart, _timeEnd),
      endTime: to.substring(_timeStart, _timeEnd),
      subjectName: subjectName,
      subjectId: subjectIdsByName[subjectName],
      teacherName: _names(json['teachers']),
      roomName: optionalStringField(json, 'room'),
      topic: optionalStringField(json, 'title'),
      isCancelled: isCancelled,
      isSubstitution: json['substitution'] == _flagSet,
      isLocked: json['isLocked'] == _flagSet,
      originalSubjectName: oldSubjectName == null
          ? null
          : normalizeMobiregSubjectName(oldSubjectName),
      originalTeacherName: _names(json['oldTeachers']),
      isReplaced: replacedByEventId != null,
      replacedByEventId: replacedByEventId,
    );
  }).toList();
}

String? _names(Object? value) {
  if (value is! List || value.isEmpty) {
    return null;
  }
  return value.whereType<String>().join(_nameSeparator);
}
