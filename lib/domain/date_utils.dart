DateTime parseFlexibleDate(String value) {
  try {
    return DateTime.parse(value);
  } on FormatException {
    final parts = value.split('.');
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
