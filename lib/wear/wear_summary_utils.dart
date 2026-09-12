import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/domain/portal_date_utils.dart';

int testsWithinDays(List<PortalTest> tests, int days) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return tests
      .where(
        (test) => parsePortalDate(test.date).difference(today).inDays <= days,
      )
      .length;
}

bool isDateWithinDays(String date, int days) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = parsePortalDate(date).difference(today).inDays;
  return diff >= 0 && diff <= days;
}
