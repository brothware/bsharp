import 'package:bsharp/data/providers/mobireg/parsers/json_fields.dart';
import 'package:bsharp/data/services/mobireg_translations.dart';
import 'package:bsharp/domain/entities/subject.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/entities/term.dart';

const _termsView = 'terms';
const _subjectsView = 'subjects';
const _yearFlag = 1;
const _noParentId = 0;

List<Term> parseTerms(Object data) {
  return objectsOf(data, _termsView).map((json) {
    final parentId = intField(json, 'parentId', _termsView);
    final isYear = intField(json, 'isYear', _termsView) == _yearFlag;
    return Term(
      id: intField(json, 'id', _termsView),
      name: normalizeMobiregTermName(stringField(json, 'label', _termsView)),
      type: isYear ? TermType.year : TermType.semester,
      startDate: DateTime.parse(stringField(json, 'dateFrom', _termsView)),
      endDate: DateTime.parse(stringField(json, 'dateTo', _termsView)),
      parentId: parentId == _noParentId ? null : parentId,
    );
  }).toList();
}

List<Subject> parseSubjects(Object data) {
  return objectsOf(data, _subjectsView).map((json) {
    final name = normalizeMobiregSubjectName(
      stringField(json, 'label', _subjectsView),
    );
    return Subject(
      id: intField(json, 'id', _subjectsView),
      name: name,
      abbr: name,
    );
  }).toList();
}
