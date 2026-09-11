import 'dart:ui';

import 'package:bsharp/core/constants/semantic_color.dart';
import 'package:bsharp/core/constants/semantic_palette.dart';
import 'package:bsharp/domain/entities/resolved_grade.dart';

class SubjectGrades {
  SubjectGrades({
    required this.subjectName,
    required this.subjectId,
    required this.grades,
  });

  final String subjectName;
  final int subjectId;
  final List<ResolvedGrade> grades;

  Iterable<ResolvedGrade> get _gradeable => grades.where(
    (g) => g.countsToAverage && g.effectiveValue != null && g.weight > 0,
  );

  double? get weightedAverage {
    final marks = _gradeable.toList();
    if (marks.isEmpty) return null;

    var totalWeight = 0;
    var weightedSum = 0.0;
    for (final g in marks) {
      weightedSum += g.effectiveValue! * g.weight;
      totalWeight += g.weight;
    }
    if (totalWeight == 0) return null;
    return weightedSum / totalWeight;
  }

  double? get simpleAverage {
    final marks = _gradeable.toList();
    if (marks.isEmpty) return null;
    final sum = marks.fold<double>(0, (acc, g) => acc + g.effectiveValue!);
    return sum / marks.length;
  }
}

Color gradeColor(double? value, {required Brightness brightness}) {
  final token = switch (value) {
    null => SemanticColor.gradeSatisfactory,
    >= 5.5 => SemanticColor.gradeExcellent,
    >= 4.5 => SemanticColor.gradeVeryGood,
    >= 3.5 => SemanticColor.gradeGood,
    >= 2.5 => SemanticColor.gradeSatisfactory,
    >= 1.5 => SemanticColor.gradeAcceptable,
    _ => SemanticColor.gradeFailing,
  };
  return SemanticPalette.resolve(token, brightness);
}

String formatAverage(double? avg) {
  if (avg == null) return '-';
  return avg.toStringAsFixed(2);
}
