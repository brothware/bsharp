import 'package:bsharp/domain/entities/mark.dart';
import 'package:bsharp/domain/entities/subject.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/entities/teacher.dart';
import 'package:bsharp/domain/entities/term.dart';
import 'package:bsharp/domain/grade_utils.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'grades_providers.g.dart';

@Riverpod(keepAlive: true)
class Marks extends _$Marks {
  @override
  List<Mark> build() => [];
  List<Mark> get value => state;
  set value(List<Mark> v) => state = v;
}

@Riverpod(keepAlive: true)
class MarkGroups extends _$MarkGroups {
  @override
  List<MarkGroup> build() => [];
  List<MarkGroup> get value => state;
  set value(List<MarkGroup> v) => state = v;
}

@Riverpod(keepAlive: true)
class MarkScales extends _$MarkScales {
  @override
  List<MarkScale> build() => [];
  List<MarkScale> get value => state;
  set value(List<MarkScale> v) => state = v;
}

@Riverpod(keepAlive: true)
class MarkKinds extends _$MarkKinds {
  @override
  List<MarkKind> build() => [];
  List<MarkKind> get value => state;
  set value(List<MarkKind> v) => state = v;
}

@Riverpod(keepAlive: true)
class MarkGroupGroups extends _$MarkGroupGroups {
  @override
  List<MarkGroupGroup> build() => [];
  List<MarkGroupGroup> get value => state;
  set value(List<MarkGroupGroup> v) => state = v;
}

@Riverpod(keepAlive: true)
class Subjects extends _$Subjects {
  @override
  List<Subject> build() => [];
  List<Subject> get value => state;
  set value(List<Subject> v) => state = v;
}

@Riverpod(keepAlive: true)
class Teachers extends _$Teachers {
  @override
  List<Teacher> build() => [];
  List<Teacher> get value => state;
  set value(List<Teacher> v) => state = v;
}

@Riverpod(keepAlive: true)
class Terms extends _$Terms {
  @override
  List<Term> build() => [];
  List<Term> get value => state;
  set value(List<Term> v) => state = v;
}

@Riverpod(keepAlive: true)
class SelectedTermId extends _$SelectedTermId {
  @override
  int? build() => null;
  int? get value => state;
  set value(int? v) => state = v;
}

@Riverpod(keepAlive: true)
class NewGradeIds extends _$NewGradeIds {
  @override
  Set<int> build() => {};
  Set<int> get value => state;
  set value(Set<int> v) => state = v;
}

@Riverpod(keepAlive: true)
Term? currentTerm(Ref ref) {
  final terms = ref.watch(termsProvider);
  final selectedId = ref.watch(selectedTermIdProvider);

  if (selectedId != null) {
    final match = terms.where((t) => t.id == selectedId);
    if (match.isNotEmpty) return match.first;
  }

  final now = DateTime.now();
  final current = terms.where(
    (t) => t.startDate.isBefore(now) && t.endDate.isAfter(now),
  );
  if (current.isNotEmpty) {
    final semester = current.where((t) => t.type == TermType.semester);
    if (semester.isNotEmpty) return semester.first;
    return current.first;
  }
  return terms.isNotEmpty ? terms.first : null;
}

@Riverpod(keepAlive: true)
List<SubjectGrades> subjectGrades(Ref ref) {
  final marks = ref.watch(marksProvider);
  final groups = ref.watch(markGroupsProvider);
  final scales = ref.watch(markScalesProvider);
  final kinds = ref.watch(markKindsProvider);
  final groupGroups = ref.watch(markGroupGroupsProvider);
  final eventTypeTerms = ref.watch(eventTypeTermsProvider);
  final eventTypes = ref.watch(eventTypesProvider);
  final subjects = ref.watch(subjectsProvider);
  final term = ref.watch(currentTermProvider);
  final terms = ref.watch(termsProvider);

  final groupById = {for (final g in groups) g.id: g};
  final scaleById = {for (final s in scales) s.id: s};
  final kindById = {for (final k in kinds) k.id: k};
  final groupGroupById = {for (final gg in groupGroups) gg.id: gg};
  final eventTypeTermById = {for (final ett in eventTypeTerms) ett.id: ett};
  final eventTypeById = {for (final et in eventTypes) et.id: et};
  final subjectById = {for (final s in subjects) s.id: s};

  final allowedTermIds = <int>{};
  if (term != null) {
    allowedTermIds.add(term.id);
    if (term.type == TermType.year) {
      for (final t in terms) {
        if (t.parentId == term.id) allowedTermIds.add(t.id);
      }
    }
  }

  bool matchesTerm(MarkGroup group) {
    if (allowedTermIds.isEmpty) return true;
    if (group.eventTypeTermsId == null) return true;
    final ett = eventTypeTermById[group.eventTypeTermsId];
    if (ett == null) return true;
    return allowedTermIds.contains(ett.termsId);
  }

  int? subjectIdForMarkGroup(MarkGroup group) {
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

  String? fallbackNameForGroup(MarkGroup group) {
    if (group.markKindsId != null) {
      final kind = kindById[group.markKindsId];
      if (kind != null) return translateGradeCategory(kind.name);
    }
    if (group.markGroupGroupsId != null) {
      final gg = groupGroupById[group.markGroupGroupsId];
      if (gg != null) return translateSubjectName(gg.name);
    }
    return null;
  }

  final resolvedByKey = <String, List<ResolvedMark>>{};
  final keyToName = <String, String>{};

  for (final m in marks) {
    final group = groupById[m.markGroupsId];
    if (group == null) continue;
    if (!matchesTerm(group)) continue;

    final resolved = resolveMark(
      mark: m,
      scaleById: scaleById,
      groupById: groupById,
    );

    final subjectId = subjectIdForMarkGroup(group);
    if (subjectId != null) {
      final key = 's$subjectId';
      resolvedByKey.putIfAbsent(key, () => []).add(resolved);
      if (!keyToName.containsKey(key)) {
        final subject = subjectById[subjectId];
        keyToName[key] = subject != null
            ? translateSubjectName(subject.name)
            : t.grades.other;
      }
    } else {
      final fallback = fallbackNameForGroup(group);
      if (fallback != null) {
        final key = 'f$fallback';
        resolvedByKey.putIfAbsent(key, () => []).add(resolved);
        keyToName[key] = fallback;
      } else {
        const key = 'other';
        resolvedByKey.putIfAbsent(key, () => []).add(resolved);
        keyToName[key] = t.grades.other;
      }
    }
  }

  final result = <SubjectGrades>[];
  for (final entry in resolvedByKey.entries) {
    final sorted = List<ResolvedMark>.from(entry.value)
      ..sort((a, b) => b.mark.getDate.compareTo(a.mark.getDate));

    result.add(
      SubjectGrades(
        subjectName: keyToName[entry.key]!,
        subjectId: entry.key.hashCode,
        resolvedMarks: sorted,
      ),
    );
  }

  result.sort((a, b) => a.subjectName.compareTo(b.subjectName));
  return result;
}

@Riverpod(keepAlive: true)
double? overallWeightedAverage(Ref ref) {
  final grades = ref.watch(subjectGradesProvider);
  final averages = grades
      .map((sg) => sg.weightedAverage)
      .whereType<double>()
      .toList();
  if (averages.isEmpty) return null;
  return averages.reduce((a, b) => a + b) / averages.length;
}

@Riverpod(keepAlive: true)
double? overallSimpleAverage(Ref ref) {
  final grades = ref.watch(subjectGradesProvider);
  final averages = grades
      .map((sg) => sg.simpleAverage)
      .whereType<double>()
      .toList();
  if (averages.isEmpty) return null;
  return averages.reduce((a, b) => a + b) / averages.length;
}

final gradeDistributionProvider = Provider<Map<String, int>>((ref) {
  final grades = ref.watch(subjectGradesProvider);
  final allResolved = grades.expand((sg) => sg.resolvedMarks).toList();
  return gradeDistribution(allResolved);
});
