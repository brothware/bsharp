import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/screens/wear_bulletin_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('a bulletin keeps its first line clear of the bezel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(454, 454);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          wearScreenShapeProvider.overrideWith((_) => WearScreenShape.round),
        ],
        child: const MaterialApp(
          home: WearBulletinDetailScreen(
            bulletin: PortalBulletin(
              id: 1,
              title: 'Parent-teacher meeting - March 15',
              author: 'Dyrekcja',
              date: '2026-09-14',
              content: 'The meeting starts at 17:00 in the main hall.',
              isRead: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const radius = 227.0 / 2;
    const centre = Offset(radius, radius);
    final title = tester.getRect(
      find.text('Parent-teacher meeting - March 15'),
    );

    for (final corner in [title.topLeft, title.topRight]) {
      expect(
        (corner - centre).distance,
        lessThanOrEqualTo(radius),
        reason: 'the title starts $corner, which the round bezel clips',
      );
    }
  });
}
