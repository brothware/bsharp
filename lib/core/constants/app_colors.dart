import 'dart:ui';

abstract final class AppColors {
  static const primaryGreen = Color(0xFF6AAF35);
  static const seaGreen = Color(0xFF2E8B57);
  static const primaryBlue = Color(0xFF2196F3);
  static const accentOrange = Color(0xFFFFA726);

  static const gradeExcellent = Color(0xFF4CAF50);
  static const gradeVeryGood = Color(0xFF8BC34A);
  static const gradeGood = Color(0xFFFFC107);
  static const gradeSatisfactory = Color(0xFFFF9800);
  static const gradeAcceptable = Color(0xFFFF5722);
  static const gradeFailing = Color(0xFFF44336);

  static const attendancePresent = Color(0xFF4CAF50);
  static const attendanceAbsent = Color(0xFFF44336);
  static const attendanceLate = Color(0xFFFFC107);
  static const attendanceExcused = Color(0xFF2196F3);

  static const Color gradientStart = primaryGreen;
  static const Color gradientEnd = primaryBlue;

  static const List<Color> gradientColors = [
    gradientStart,
    seaGreen,
    gradientEnd,
  ];
}
