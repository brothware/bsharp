import 'dart:ui';

import 'package:bsharp/core/constants/app_colors.dart';
import 'package:bsharp/domain/entities/mark.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';

class ResolvedMark {
  ResolvedMark({
    required this.mark,
    required this.displayValue,
    this.effectiveValue,
    this.countsToAverage = true,
    this.markMax,
  });

  final Mark mark;
  final String displayValue;
  final double? effectiveValue;
  final bool countsToAverage;
  final double? markMax;

  bool get isPointBased => markMax != null;
}

ResolvedMark resolveMark({
  required Mark mark,
  required Map<int, MarkScale> scaleById,
  required Map<int, MarkGroup> groupById,
}) {
  final group = groupById[mark.markGroupsId];
  final scale = mark.markScalesId != null ? scaleById[mark.markScalesId] : null;

  final isPointBased = group != null && group.markType == 2;
  final markMax = isPointBased ? group.markValueRangeMax : null;

  if (scale != null) {
    final countsToAverage = scale.noCountToAverage == 0;
    final effectiveValue = scale.markValue != null && scale.markValue != 0
        ? scale.markValue
        : null;

    return ResolvedMark(
      mark: mark,
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

    return ResolvedMark(
      mark: mark,
      displayValue: display,
      effectiveValue: effectiveValue,
      markMax: markMax,
    );
  }

  return ResolvedMark(mark: mark, displayValue: '?', countsToAverage: false);
}

class SubjectGrades {
  SubjectGrades({
    required this.subjectName,
    required this.subjectId,
    required this.resolvedMarks,
  });

  final String subjectName;
  final int subjectId;
  final List<ResolvedMark> resolvedMarks;

  Iterable<ResolvedMark> get _gradeable => resolvedMarks.where(
    (rm) =>
        rm.countsToAverage && rm.effectiveValue != null && rm.mark.weight > 0,
  );

  double? get weightedAverage {
    final marks = _gradeable.toList();
    if (marks.isEmpty) return null;

    var totalWeight = 0;
    var weightedSum = 0.0;
    for (final rm in marks) {
      weightedSum += rm.effectiveValue! * rm.mark.weight;
      totalWeight += rm.mark.weight;
    }
    if (totalWeight == 0) return null;
    return weightedSum / totalWeight;
  }

  double? get simpleAverage {
    final marks = _gradeable.toList();
    if (marks.isEmpty) return null;
    final sum = marks.fold<double>(0, (acc, rm) => acc + rm.effectiveValue!);
    return sum / marks.length;
  }
}

Color gradeColor(double? value) {
  if (value == null) return AppColors.gradeSatisfactory;
  if (value >= 5.5) return AppColors.gradeExcellent;
  if (value >= 4.5) return AppColors.gradeVeryGood;
  if (value >= 3.5) return AppColors.gradeGood;
  if (value >= 2.5) return AppColors.gradeSatisfactory;
  if (value >= 1.5) return AppColors.gradeAcceptable;
  return AppColors.gradeFailing;
}

String formatAverage(double? avg) {
  if (avg == null) return '-';
  return avg.toStringAsFixed(2);
}

String translateGradeName(String name) {
  final trimmed = name.trim();
  final key = trimmed.toLowerCase();
  final map = <String, String>{
    'celujący': t.gradeNames.celujacy,
    'celujący z minusem': t.gradeNames.celujacyMinus,
    'bardzo dobry z plusem': t.gradeNames.bardzoDobryPlus,
    'bardzo dobry': t.gradeNames.bardzoDobry,
    'bardzo dobry z minusem': t.gradeNames.bardzoDobryMinus,
    'dobry z plusem': t.gradeNames.dobryPlus,
    'dobry': t.gradeNames.dobry,
    'dobry z minusem': t.gradeNames.dobryMinus,
    'dostateczny z plusem': t.gradeNames.dostatecznyPlus,
    'dostateczny': t.gradeNames.dostateczny,
    'dostateczny z minusem': t.gradeNames.dostatecznyMinus,
    'dopuszczający z plusem': t.gradeNames.dopuszczajacyPlus,
    'dopuszczający': t.gradeNames.dopuszczajacy,
    'dopuszczający z minusem': t.gradeNames.dopuszczajacyMinus,
    'niedostateczny z plusem': t.gradeNames.niedostatecznyPlus,
    'niedostateczny': t.gradeNames.niedostateczny,
    'nieklasyfikowany': t.gradeNames.nieklasyfikowany,
    'nieklasyfikowana': t.gradeNames.nieklasyfikowany,
    'zwolniony': t.gradeNames.zwolniony,
    'zwolniona': t.gradeNames.zwolniony,
    'szóstka': t.gradeNames.szostka,
    'piątka z plusem': t.gradeNames.piatkaPlus,
    'piątka': t.gradeNames.piatka,
    'piątka z minusem': t.gradeNames.piatkaMinus,
    'czwórka z plusem': t.gradeNames.czworkaPlus,
    'czwórka': t.gradeNames.czworka,
    'czwórka z minusem': t.gradeNames.czworkaMinus,
    'trójka z plusem': t.gradeNames.trojkaPlus,
    'trójka': t.gradeNames.trojka,
    'trójka z minusem': t.gradeNames.trojkaMinus,
    'dwójka z plusem': t.gradeNames.dwojkaPlus,
    'dwójka': t.gradeNames.dwojka,
    'dwójka z minusem': t.gradeNames.dwojkaMinus,
    'jedynka z plusem': t.gradeNames.jedynkaPlus,
    'jedynka': t.gradeNames.jedynka,
    'wspaniale': t.gradeNames.wspaniale,
    'bardzo dobrze': t.gradeNames.bardzoDobrze,
    'dobrze': t.gradeNames.dobrze,
    'poprawnie': t.gradeNames.poprawnie,
    'słabo': t.gradeNames.slabo,
    'znakomicie': t.gradeNames.znakomicie,
    'celująco': t.gradeNames.celujaco,
    'wybitnie': t.gradeNames.wybitnie,
    'zadowalająco': t.gradeNames.zadowalajaco,
    'przeciętnie': t.gradeNames.przecietnie,
    'niezadowalająco': t.gradeNames.niezadowalajaco,
    'nieodpowiednio': t.gradeNames.nieodpowiednio,
    'wzorowe': t.gradeNames.wzorowe,
    'bardzo dobre': t.gradeNames.bardzoDobre,
    'dobre': t.gradeNames.dobre,
    'poprawne': t.gradeNames.poprawne,
    'nieodpowiednie': t.gradeNames.nieodpowiednie,
    'naganne': t.gradeNames.naganne,
    'nieobecny': t.gradeNames.nieobecny,
    'nieobecna': t.gradeNames.nieobecny,
    'brak zadania': t.gradeNames.brakZadania,
    'nieprzygotowany': t.gradeNames.nieprzygotowany,
    'nieprzygotowana': t.gradeNames.nieprzygotowany,
  };
  final value = map[key];
  if (value == null) return name;
  return matchCase(trimmed, value);
}

String translateGradeCategory(String name) {
  final trimmed = name.trim();
  final key = trimmed.toLowerCase();
  final map = <String, String>{
    'sprawdzian': t.gradeCategories.sprawdzian,
    'kartkówka': t.gradeCategories.kartkowka,
    'odpowiedź ustna': t.gradeCategories.odpowiedzUstna,
    'praca domowa': t.gradeCategories.pracaDomowa,
    'aktywność': t.gradeCategories.aktywnosc,
    'projekt': t.gradeCategories.projekt,
    'wypracowanie': t.gradeCategories.wypracowanie,
    'dyktando': t.gradeCategories.dyktando,
    'referat': t.gradeCategories.referat,
    'praca klasowa': t.gradeCategories.pracaKlasowa,
    'zadanie': t.gradeCategories.zadanie,
    'test': t.gradeCategories.test,
    'ćwiczenie': t.gradeCategories.cwiczenie,
    'recytacja': t.gradeCategories.recytacja,
    'czytanie': t.gradeCategories.czytanie,
    'zachowanie': t.gradeCategories.zachowanie,
  };
  final value = map[key];
  if (value == null) return name;
  return matchCase(trimmed, value);
}

Map<String, int> gradeDistribution(List<ResolvedMark> resolvedMarks) {
  final dist = <String, int>{};
  for (final rm in resolvedMarks) {
    final v = rm.effectiveValue;
    if (v == null) continue;
    final key = v.round().toString();
    dist[key] = (dist[key] ?? 0) + 1;
  }
  return dist;
}
