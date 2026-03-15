import 'package:bsharp/domain/entities/resolved_grade.dart';
import 'package:bsharp/domain/entities/subject.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/entities/teacher.dart';
import 'package:bsharp/domain/entities/term.dart';
import 'package:bsharp/domain/grade_utils.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'grades_providers.g.dart';

@Riverpod(keepAlive: true)
class ResolvedGrades extends _$ResolvedGrades {
  @override
  List<ResolvedGrade> build() => [];
  List<ResolvedGrade> get value => state;
  set value(List<ResolvedGrade> v) => state = v;
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

final newGradeIdsProvider = NotifierProvider<NewGradeIdsNotifier, Set<int>>(
  NewGradeIdsNotifier.new,
);

class NewGradeIdsNotifier extends Notifier<Set<int>> {
  static const _key = 'new_grade_ids';

  @override
  Set<int> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getStringList(_key);
    if (stored == null) return {};
    return stored.map(int.parse).toSet();
  }

  Future<void> addNewIds(Set<int> ids) async {
    if (ids.isEmpty) return;
    final updated = {...state, ...ids};
    await _persist(updated);
    state = updated;
  }

  Future<void> markAsRead(int id) async {
    if (!state.contains(id)) return;
    final updated = {...state}..remove(id);
    await _persist(updated);
    state = updated;
  }

  Future<void> _persist(Set<int> ids) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_key, ids.map((e) => e.toString()).toList());
  }
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
  final resolved = ref.watch(resolvedGradesProvider);

  final bySubject = <String, List<ResolvedGrade>>{};
  final subjectIds = <String, int>{};

  for (final g in resolved) {
    final key = g.subjectName;
    bySubject.putIfAbsent(key, () => []).add(g);
    subjectIds.putIfAbsent(key, () => g.subjectId ?? key.hashCode);
  }

  final result = <SubjectGrades>[];
  for (final entry in bySubject.entries) {
    final sorted = List<ResolvedGrade>.from(entry.value)
      ..sort((a, b) => a.date.compareTo(b.date));

    final displayName = translateSubjectName(entry.key);

    result.add(
      SubjectGrades(
        subjectName: displayName,
        subjectId: subjectIds[entry.key]!,
        grades: sorted,
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
  final allValues = grades
      .expand((sg) => sg.grades)
      .map((g) => g.effectiveValue)
      .toList();
  return gradeDistribution(allValues);
});
