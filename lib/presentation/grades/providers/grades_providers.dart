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

final marksProvider = StateProvider<List<Mark>>((ref) => []);

final markGroupsProvider = StateProvider<List<MarkGroup>>((ref) => []);

final markScalesProvider = StateProvider<List<MarkScale>>((ref) => []);

final markKindsProvider = StateProvider<List<MarkKind>>((ref) => []);

final markGroupGroupsProvider = StateProvider<List<MarkGroupGroup>>(
  (ref) => [],
);

final subjectsProvider = StateProvider<List<Subject>>((ref) => []);

final teachersProvider = StateProvider<List<Teacher>>((ref) => []);

final termsProvider = StateProvider<List<Term>>((ref) => []);

final selectedTermIdProvider = StateProvider<int?>((ref) => null);

final newGradeIdsProvider = StateProvider<Set<int>>((ref) => {});

final currentTermProvider = Provider<Term?>((ref) {
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
});

final subjectGradesProvider = Provider<List<SubjectGrades>>((ref) {
  final marks = ref.watch(marksProvider);
  final groups = ref.watch(markGroupsProvider);
  final scales = ref.watch(markScalesProvider);
  final kinds = ref.watch(markKindsProvider);
  final groupGroups = ref.watch(markGroupGroupsProvider);
  final eventTypeTerms = ref.watch(eventTypeTermsProvider);
  final eventTypes = ref.watch(eventTypesProvider);
  final subjects = ref.watch(subjectsProvider);
  final currentTerm = ref.watch(currentTermProvider);
  final terms = ref.watch(termsProvider);

  final groupById = {for (final g in groups) g.id: g};
  final scaleById = {for (final s in scales) s.id: s};
  final kindById = {for (final k in kinds) k.id: k};
  final groupGroupById = {for (final gg in groupGroups) gg.id: gg};
  final eventTypeTermById = {for (final ett in eventTypeTerms) ett.id: ett};
  final eventTypeById = {for (final et in eventTypes) et.id: et};
  final subjectById = {for (final s in subjects) s.id: s};

  final allowedTermIds = <int>{};
  if (currentTerm != null) {
    allowedTermIds.add(currentTerm.id);
    if (currentTerm.type == TermType.year) {
      for (final t in terms) {
        if (t.parentId == currentTerm.id) allowedTermIds.add(t.id);
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
});

final overallWeightedAverageProvider = Provider<double?>((ref) {
  final subjectGrades = ref.watch(subjectGradesProvider);
  final averages = subjectGrades
      .map((sg) => sg.weightedAverage)
      .whereType<double>()
      .toList();
  if (averages.isEmpty) return null;
  return averages.reduce((a, b) => a + b) / averages.length;
});

final overallSimpleAverageProvider = Provider<double?>((ref) {
  final subjectGrades = ref.watch(subjectGradesProvider);
  final averages = subjectGrades
      .map((sg) => sg.simpleAverage)
      .whereType<double>()
      .toList();
  if (averages.isEmpty) return null;
  return averages.reduce((a, b) => a + b) / averages.length;
});

final gradeDistributionProvider = Provider<Map<String, int>>((ref) {
  final subjectGrades = ref.watch(subjectGradesProvider);
  final allResolved = subjectGrades.expand((sg) => sg.resolvedMarks).toList();
  return gradeDistribution(allResolved);
});
