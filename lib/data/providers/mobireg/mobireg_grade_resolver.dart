import 'package:bsharp/data/services/mobireg_translations.dart';
import 'package:bsharp/domain/entities/event.dart';
import 'package:bsharp/domain/entities/mark.dart';
import 'package:bsharp/domain/entities/resolved_grade.dart';
import 'package:bsharp/domain/entities/subject.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/entities/teacher.dart';
import 'package:bsharp/domain/entities/term.dart';

class MobiregGradeResolver {
  List<ResolvedGrade> resolve({
    required List<Mark> marks,
    required List<MarkGroup> markGroups,
    required List<MarkScale> markScales,
    required List<MarkKind> markKinds,
    required List<MarkGroupGroup> markGroupGroups,
    required List<EventTypeTerm> eventTypeTerms,
    required List<EventType> eventTypes,
    required List<Subject> subjects,
    required List<Teacher> teachers,
    required List<Term> terms,
    Term? currentTerm,
  }) {
    final groupById = {for (final g in markGroups) g.id: g};
    final scaleById = {for (final s in markScales) s.id: s};
    final kindById = {for (final k in markKinds) k.id: k};
    final groupGroupById = {for (final gg in markGroupGroups) gg.id: gg};
    final eventTypeTermById = {for (final ett in eventTypeTerms) ett.id: ett};
    final eventTypeById = {for (final et in eventTypes) et.id: et};
    final subjectById = {for (final s in subjects) s.id: s};
    final teacherById = {for (final t in teachers) t.id: t};

    final allowedTermIds = <int>{};
    if (currentTerm != null) {
      allowedTermIds.add(currentTerm.id);
      if (currentTerm.type == TermType.year) {
        for (final t in terms) {
          if (t.parentId == currentTerm.id) allowedTermIds.add(t.id);
        }
      }
    }

    final result = <ResolvedGrade>[];

    for (final m in marks) {
      final group = groupById[m.markGroupsId];
      if (group == null) continue;

      if (allowedTermIds.isNotEmpty && group.eventTypeTermsId != null) {
        final ett = eventTypeTermById[group.eventTypeTermsId];
        if (ett != null && !allowedTermIds.contains(ett.termsId)) continue;
      }

      final subjectId = _resolveSubjectId(
        group,
        eventTypeTermById,
        eventTypeById,
        kindById,
      );
      final subjectName = _resolveSubjectName(
        subjectId,
        group,
        subjectById,
        kindById,
        groupGroupById,
      );

      final categoryName = _resolveCategoryName(group, kindById);

      final resolved = _resolveMark(m, group, scaleById);

      final teacher = teacherById[m.teacherUsersId];
      final teacherName = teacher != null
          ? '${teacher.name} ${teacher.surname}'
          : null;

      int? termId;
      if (group.eventTypeTermsId != null) {
        final ett = eventTypeTermById[group.eventTypeTermsId];
        termId = ett?.termsId;
      }

      final kind = group.markKindsId != null
          ? kindById[group.markKindsId]
          : null;
      final effectiveWeight =
          m.weight ?? group.weight ?? kind?.defaultWeight ?? 1;

      result.add(
        ResolvedGrade(
          id: m.id,
          subjectName: subjectName,
          categoryName: categoryName,
          displayValue: resolved.displayValue,
          date: m.getDate,
          effectiveValue: resolved.effectiveValue,
          countsToAverage: resolved.countsToAverage,
          weight: effectiveWeight,
          description: group.description,
          teacherName: teacherName,
          comment: m.comments,
          markMax: resolved.markMax,
          termId: termId,
          subjectId: subjectId,
        ),
      );
    }

    return result;
  }

  int? _resolveSubjectId(
    MarkGroup group,
    Map<int, EventTypeTerm> eventTypeTermById,
    Map<int, EventType> eventTypeById,
    Map<int, MarkKind> kindById,
  ) {
    if (group.eventTypeTermsId != null) {
      final ett = eventTypeTermById[group.eventTypeTermsId];
      if (ett != null) {
        final et = eventTypeById[ett.eventTypesId];
        if (et?.subjectsId != null) return et!.subjectsId;
      }
    }
    if (group.markKindsId != null) {
      final kind = kindById[group.markKindsId];
      if (kind?.subjectsId != null) return kind!.subjectsId;
    }
    return null;
  }

  String _resolveSubjectName(
    int? subjectId,
    MarkGroup group,
    Map<int, Subject> subjectById,
    Map<int, MarkKind> kindById,
    Map<int, MarkGroupGroup> groupGroupById,
  ) {
    if (subjectId != null) {
      final subject = subjectById[subjectId];
      if (subject != null) {
        return normalizeMobiregSubjectName(subject.name);
      }
    }

    if (group.markKindsId != null) {
      final kind = kindById[group.markKindsId];
      if (kind != null) return normalizeMobiregGradeCategory(kind.name);
    }
    if (group.markGroupGroupsId != null) {
      final gg = groupGroupById[group.markGroupGroupsId];
      if (gg != null) return normalizeMobiregSubjectName(gg.name);
    }

    return 'Other';
  }

  String _resolveCategoryName(
    MarkGroup group,
    Map<int, MarkKind> kindById,
  ) {
    if (group.markKindsId != null) {
      final kind = kindById[group.markKindsId];
      if (kind != null) return normalizeMobiregGradeCategory(kind.name);
    }
    return '';
  }

  _ResolvedMarkData _resolveMark(
    Mark mark,
    MarkGroup group,
    Map<int, MarkScale> scaleById,
  ) {
    final scale = mark.markScalesId != null
        ? scaleById[mark.markScalesId]
        : null;
    final isPointBased = group.markType == 2;
    final markMax = isPointBased ? group.markValueRangeMax : null;

    if (scale != null) {
      final countsToAverage = scale.noCountToAverage == 0;
      final effectiveValue = scale.markValue != null && scale.markValue != 0
          ? scale.markValue
          : null;
      return _ResolvedMarkData(
        displayValue: scale.abbreviation,
        effectiveValue: effectiveValue,
        countsToAverage: countsToAverage,
        markMax: markMax,
      );
    }

    if (mark.markValue != null) {
      String display;
      double? effectiveValue;
      if (isPointBased && markMax != null) {
        final v = mark.markValue!;
        final vStr = v == v.roundToDouble()
            ? v.toInt().toString()
            : v.toStringAsFixed(1);
        final mStr = markMax == markMax.roundToDouble()
            ? markMax.toInt().toString()
            : markMax.toStringAsFixed(1);
        display = '$vStr/$mStr';
        final markMin = group.markValueRangeMin ?? 0;
        final range = markMax - markMin;
        if (range > 0) {
          final raw = 1.0 + ((v - markMin) / range) * 5.0;
          effectiveValue = (raw * 2).roundToDouble() / 2;
        }
      } else {
        final v = mark.markValue!;
        display = v == v.roundToDouble()
            ? v.toInt().toString()
            : v.toStringAsFixed(1);
        effectiveValue = mark.markValue;
      }
      return _ResolvedMarkData(
        displayValue: display,
        effectiveValue: effectiveValue,
        markMax: markMax,
      );
    }

    return const _ResolvedMarkData(
      displayValue: '?',
      countsToAverage: false,
    );
  }
}

class _ResolvedMarkData {
  const _ResolvedMarkData({
    required this.displayValue,
    this.effectiveValue,
    this.countsToAverage = true,
    this.markMax,
  });

  final String displayValue;
  final double? effectiveValue;
  final bool countsToAverage;
  final double? markMax;
}
