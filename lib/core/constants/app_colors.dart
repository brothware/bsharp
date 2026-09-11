import 'dart:ui';

abstract final class AppColors {
  static const primaryGreen = Color(0xFF6AAF35);
  static const seaGreen = Color(0xFF2E8B57);
  static const primaryBlue = Color(0xFF2196F3);

  static const Color gradientStart = primaryGreen;
  static const Color gradientEnd = primaryBlue;

  static const List<Color> gradientColors = [
    gradientStart,
    seaGreen,
    gradientEnd,
  ];
}
