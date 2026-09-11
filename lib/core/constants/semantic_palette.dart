import 'dart:ui';

import 'package:bsharp/core/constants/semantic_color.dart';

abstract final class SemanticPalette {
  static const light = <SemanticColor, Color>{
    SemanticColor.brandPrimary: Color(0xFF2A7F4F),
    SemanticColor.brandSecondary: Color(0xFF1565C0),
    SemanticColor.brandTertiary: Color(0xFFA85F00),
    SemanticColor.gradeExcellent: Color(0xFF2E7D32),
    SemanticColor.gradeVeryGood: Color(0xFF4B7C1F),
    SemanticColor.gradeGood: Color(0xFF8D6E00),
    SemanticColor.gradeSatisfactory: Color(0xFFC44100),
    SemanticColor.gradeAcceptable: Color(0xFFBF360C),
    SemanticColor.gradeFailing: Color(0xFFC62828),
    SemanticColor.statusPresent: Color(0xFF2E7D32),
    SemanticColor.statusExcused: Color(0xFF1565C0),
    SemanticColor.statusUnexcused: Color(0xFFC62828),
    SemanticColor.statusLate: Color(0xFFA85F00),
    SemanticColor.statusMixed: Color(0xFFA85F00),
    SemanticColor.statusNoData: Color(0xFF6E6E6E),
  };

  static const dark = <SemanticColor, Color>{
    SemanticColor.brandPrimary: Color(0xFF3FBE7A),
    SemanticColor.brandSecondary: Color(0xFF2196F3),
    SemanticColor.brandTertiary: Color(0xFFFFA726),
    SemanticColor.gradeExcellent: Color(0xFF4CAF50),
    SemanticColor.gradeVeryGood: Color(0xFF8BC34A),
    SemanticColor.gradeGood: Color(0xFFFFC107),
    SemanticColor.gradeSatisfactory: Color(0xFFFF9800),
    SemanticColor.gradeAcceptable: Color(0xFFFF5722),
    SemanticColor.gradeFailing: Color(0xFFF44336),
    SemanticColor.statusPresent: Color(0xFF4CAF50),
    SemanticColor.statusExcused: Color(0xFF42A5F5),
    SemanticColor.statusUnexcused: Color(0xFFF44336),
    SemanticColor.statusLate: Color(0xFFFFA726),
    SemanticColor.statusMixed: Color(0xFFFFA726),
    SemanticColor.statusNoData: Color(0xFFBDBDBD),
  };

  static Color resolve(SemanticColor token, Brightness brightness) {
    final palette = brightness == Brightness.dark ? dark : light;
    return palette[token]!;
  }
}
