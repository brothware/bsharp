import 'package:bsharp/data/providers/mobireg/parsers/json_fields.dart';
import 'package:bsharp/data/services/mobireg_translations.dart';
import 'package:bsharp/domain/entities/resolved_grade.dart';
import 'package:bsharp/domain/entities/teacher.dart';
import 'package:flutter/foundation.dart';

const _view = 'marks';
const _plusBonus = 0.5;
const _minusPenalty = 0.25;
const _defaultWeight = 1;
final _gradePattern = RegExp(r'^([1-6])([+-]?)$');

@immutable
class GradeValue {
  const GradeValue({required this.display, this.numeric});

  final String display;
  final double? numeric;
}

@immutable
class ParsedMarks {
  const ParsedMarks({required this.grades, required this.teachers});

  final List<ResolvedGrade> grades;
  final List<Teacher> teachers;
}

GradeValue gradeValueOf(String raw) {
  final match = _gradePattern.firstMatch(raw.trim());
  if (match == null) {
    return GradeValue(display: raw);
  }
  final base = int.parse(match.group(1)!);
  final modifier = switch (match.group(2)) {
    '+' => _plusBonus,
    '-' => -_minusPenalty,
    _ => 0.0,
  };
  return GradeValue(display: raw, numeric: base + modifier);
}

ParsedMarks parseMarks(Object data, {required int termId}) {
  if (data is! Map<String, dynamic>) {
    throw FormatException('View $_view: expected an object', data);
  }
  final teachers = _teachersOf(data['teachers']);
  final teacherNames = {
    for (final teacher in teachers)
      teacher.id: '${teacher.name} ${teacher.surname}',
  };
  final subjectNames = {
    for (final subject in objectsOf(data['subjects'], _view))
      intField(subject, 'id', _view): normalizeMobiregSubjectName(
        stringField(subject, 'label', _view),
      ),
  };
  final grades = objectsOf(data['grades'], _view).map((json) {
    final value = gradeValueOf(stringField(json, 'value', _view));
    final subjectId = intField(json, 'subjectId', _view);
    final weight = json['weight'];
    return ResolvedGrade(
      id: intField(json, 'id', _view),
      subjectName: subjectNames[subjectId] ?? '',
      subjectId: subjectId,
      categoryName: normalizeMobiregGradeCategory(
        optionalStringField(json, 'kindLabel') ?? '',
      ),
      displayValue: value.display,
      effectiveValue: value.numeric,
      countsToAverage: value.numeric != null && json['count_to_avg'] != 0,
      weight: weight is int ? weight : _defaultWeight,
      date: DateTime.parse(stringField(json, 'date', _view)),
      description: optionalStringField(json, 'description'),
      comment: optionalStringField(json, 'comments'),
      teacherName: teacherNames[json['teacherId']],
      termId: termId,
    );
  }).toList();
  return ParsedMarks(grades: grades, teachers: teachers);
}

List<Teacher> _teachersOf(Object? data) {
  if (data is List && data.isEmpty) {
    return const [];
  }
  if (data is! Map<String, dynamic>) {
    throw FormatException('View $_view: "teachers" is not a map', data);
  }
  return data.values.map((value) {
    if (value is! Map<String, dynamic>) {
      throw FormatException('View $_view: teacher is not an object', value);
    }
    return Teacher(
      id: intField(value, 'id', _view),
      name: stringField(value, 'first_name', _view),
      surname: stringField(value, 'surname', _view),
    );
  }).toList();
}
