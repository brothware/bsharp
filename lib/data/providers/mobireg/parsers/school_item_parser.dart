import 'package:bsharp/data/providers/mobireg/parsers/json_fields.dart';
import 'package:bsharp/data/services/mobireg_translations.dart';
import 'package:bsharp/domain/entities/portal.dart';

const _dateLength = 10;
const _praiseKind = 2;
const _praiseType = 1;
const _remarkType = 2;

List<PortalTest> parseTestItems(Object data) {
  const view = 'tests';
  return objectsOf(_field(data, 'items', view), view).map((json) {
    return PortalTest(
      id: intField(json, 'id', view),
      subjectName: normalizeMobiregSubjectName(
        stringField(json, 'subjectName', view),
      ),
      date: _datePart(stringField(json, 'dateTime', view), view),
      title: optionalStringField(json, 'title'),
      description: optionalStringField(json, 'description'),
    );
  }).toList();
}

List<PortalReprimand> parseReprimandItems(Object data) {
  const view = 'reprimands';
  return objectsOf(_field(data, 'items', view), view).map((json) {
    return PortalReprimand(
      id: intField(json, 'id', view),
      date: _datePart(stringField(json, 'getDate', view), view),
      teacherName: optionalStringField(json, 'teacherName') ?? '',
      content: stringField(json, 'content', view),
      type: intField(json, 'kind', view) == _praiseKind
          ? _praiseType
          : _remarkType,
    );
  }).toList();
}

List<PortalBulletin> parseAnnouncements(Object data) {
  const view = 'announcements';
  return objectsOf(_field(data, 'data', view), view).map((json) {
    return PortalBulletin(
      id: intField(json, 'id', view),
      title: stringField(json, 'title', view),
      content: optionalStringField(json, 'content') ?? '',
      date: _localDateTime(stringField(json, 'dateTime', view), view),
      author:
          optionalStringField(json, 'author') ??
          optionalStringField(json, 'login') ??
          '',
      isRead: json['read'] != null,
    );
  }).toList();
}

Object? _field(Object data, String key, String view) {
  if (data is! Map<String, dynamic>) {
    throw FormatException('View $view: expected an object', data.runtimeType);
  }
  return data[key];
}

DateTime _localDateTime(String dateTime, String view) {
  final parsed = DateTime.tryParse(dateTime);
  if (parsed == null) {
    throw FormatException('View $view: a date field is not a date', dateTime);
  }
  return parsed.toLocal();
}

String _datePart(String dateTime, String view) {
  if (dateTime.length < _dateLength) {
    throw FormatException('View $view: a date field is not a date');
  }
  return dateTime.substring(0, _dateLength);
}
