import 'package:bsharp/core/constants/semantic_color.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SemanticColor covers every shared token', () {
    expect(SemanticColor.values.length, 19);
  });
}
