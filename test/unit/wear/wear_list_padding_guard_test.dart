import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _argumentsFrom(String source, int start) {
  var depth = 1;
  var index = start;
  while (depth > 0 && index < source.length) {
    final char = source[index];
    if (char == '(') {
      depth++;
    } else if (char == ')') {
      depth--;
    }
    index++;
  }
  return source.substring(start, index);
}

void main() {
  test('every list on the watch sets its padding (WO-V16)', () {
    final call = RegExp(r'ListView(\.builder)?\(');
    final missing = <String>[];
    for (final entity in Directory('lib/wear').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final source = entity.readAsStringSync();
      for (final match in call.allMatches(source)) {
        final arguments = _argumentsFrom(source, match.end);
        final hasPadding =
            arguments.contains('padding:') &&
            !arguments.contains('padding: EdgeInsets.zero');
        if (!hasPadding) {
          final line = '\n'.allMatches(source.substring(0, match.start)).length;
          missing.add('${entity.path}:${line + 1}');
        }
      }
    }

    expect(
      missing,
      isEmpty,
      reason:
          'without wearListPadding the last row of a round list cannot '
          'scroll up off the bezel',
    );
  });
}
