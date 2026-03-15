import 'dart:math';

import 'package:bsharp/data/providers/demo/demo_schedule_data.dart';
import 'package:bsharp/domain/entities/resolved_grade.dart';
import 'package:bsharp/domain/entities/subject.dart';
import 'package:bsharp/domain/entities/teacher.dart';

const _categoryNames = ['Exam', 'Quiz', 'Oral answer', 'Homework', 'Activity'];
const _categoryWeights = [3, 2, 2, 1, 1];

List<ResolvedGrade> buildDemoResolvedGrades(
  List<Subject> subjects,
  List<Teacher> teachers,
  DateTime now,
) {
  final rng = Random(42);
  final grades = <ResolvedGrade>[];
  var id = 1;

  final gradeValues = [
    3,
    4,
    5,
    4,
    3,
    5,
    4,
    6,
    3,
    4,
    5,
    2,
    4,
    5,
    3,
    4,
    5,
    4,
    3,
    5,
    4,
    5,
    6,
    3,
    4,
    5,
    4,
    3,
    5,
    4,
  ];
  final scaleAbbreviations = ['1', '2', '3', '4', '5', '6'];

  var gradeIdx = 0;
  for (
    var subIdx = 0;
    subIdx < subjects.length && gradeIdx < gradeValues.length;
    subIdx++
  ) {
    for (
      var catIdx = 0;
      catIdx < _categoryNames.length && gradeIdx < gradeValues.length;
      catIdx++
    ) {
      final gradeVal = gradeValues[gradeIdx];
      final daysAgo = rng.nextInt(60) + 1;
      final teacherIdx = demoTeacherAssignment[subIdx] - 1;
      final teacher = teachers[teacherIdx];

      grades.add(
        ResolvedGrade(
          id: id,
          subjectName: demoSubjectNames[subIdx],
          categoryName: _categoryNames[catIdx],
          displayValue: scaleAbbreviations[gradeVal - 1],
          date: now.subtract(Duration(days: daysAgo)),
          effectiveValue: gradeVal.toDouble(),
          weight: _categoryWeights[catIdx],
          teacherName: '${teacher.name} ${teacher.surname}',
          subjectId: subjects[subIdx].id,
        ),
      );
      id++;
      gradeIdx++;
    }
  }
  return grades;
}
