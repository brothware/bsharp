import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _wearRes = 'android/app/src/wear/res';
const _densities = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];
const _layers = ['ic_launcher_background', 'ic_launcher_foreground'];

void main() {
  test('the watch launcher icon is adaptive, so the launcher can make it '
      'round (WO-V6)', () {
    final adaptive = File('$_wearRes/mipmap-anydpi-v26/ic_launcher.xml');

    expect(adaptive.existsSync(), isTrue, reason: '${adaptive.path} missing');
    final xml = adaptive.readAsStringSync();
    expect(xml, contains('<adaptive-icon'));
    for (final layer in _layers) {
      expect(xml, contains('@mipmap/$layer'));
    }
  });

  test('every adaptive layer ships at every density', () {
    final missing = [
      for (final density in _densities)
        for (final layer in _layers)
          if (!File('$_wearRes/mipmap-$density/$layer.png').existsSync())
            'mipmap-$density/$layer.png',
    ];

    expect(missing, isEmpty);
  });
}
