import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Layers that must not know which school backend the app is talking to.
const _coreDirectories = [
  'lib/app',
  'lib/core',
  'lib/domain',
  'lib/presentation',
  'lib/wear',
];

/// The composition root is the one place allowed to name concrete providers.
const _allowed = {'lib/app/data_provider_registry.dart'};

const _providerImport = 'package:bsharp/data/providers/';

void main() {
  test('core layers do not import provider implementations', () {
    final offenders = <String>[];

    for (final directory in _coreDirectories) {
      final dir = Directory(directory);
      if (!dir.existsSync()) continue;

      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('.g.dart')) continue;
        if (_allowed.contains(entity.path)) continue;

        for (final line in entity.readAsLinesSync()) {
          if (!line.startsWith('import ') && !line.startsWith('export ')) {
            continue;
          }
          if (line.contains(_providerImport)) {
            offenders.add('${entity.path}: ${line.trim()}');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Core must reach a backend through SchoolDataProvider, never by '
          'importing one. Offending imports:\n${offenders.join('\n')}',
    );
  });
}
