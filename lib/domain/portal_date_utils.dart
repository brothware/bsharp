DateTime parsePortalDate(String date) {
  try {
    return DateTime.parse(date);
  } on FormatException {
    final parts = date.split('.');
    if (parts.length == 3) {
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    }
    return DateTime(2000);
  }
}

bool isPortalDateWithinDays(String date, int days) {
  final parsed = parsePortalDate(date);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = parsed.difference(today).inDays;
  return diff >= 0 && diff <= days;
}
