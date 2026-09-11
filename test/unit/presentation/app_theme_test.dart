import 'package:bsharp/core/constants/semantic_color.dart';
import 'package:bsharp/core/constants/semantic_palette.dart';
import 'package:bsharp/presentation/common/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light and dark use different brand accents', () {
    final light = AppTheme.light().colorScheme.primary;
    final dark = AppTheme.dark().colorScheme.primary;
    expect(light, isNot(dark));
  });

  test('accents come from the semantic palette', () {
    expect(
      AppTheme.light().colorScheme.primary,
      SemanticPalette.light[SemanticColor.brandPrimary],
    );
    expect(
      AppTheme.dark().colorScheme.primary,
      SemanticPalette.dark[SemanticColor.brandPrimary],
    );
  });
}
