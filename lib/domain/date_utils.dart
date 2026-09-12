import 'package:bsharp/l10n/strings.g.dart';

String monthName(int month) {
  final monthNames = [
    t.attendance.month.jan,
    t.attendance.month.feb,
    t.attendance.month.mar,
    t.attendance.month.apr,
    t.attendance.month.may,
    t.attendance.month.jun,
    t.attendance.month.jul,
    t.attendance.month.aug,
    t.attendance.month.sep,
    t.attendance.month.oct,
    t.attendance.month.nov,
    t.attendance.month.dec,
  ];
  if (month < 1 || month > 12) {
    return '';
  }
  return monthNames[month - 1];
}
