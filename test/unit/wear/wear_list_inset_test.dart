import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/screens/wear_schedule_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

void main() {
  testWidgets(
    'round list rows fill the scaffold content width, not a double inset',
    (tester) async {
      const screenSize = Size(227, 227);
      tester.view.physicalSize = const Size(454, 454);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = CredentialStorage(store: FakeKeyValueStore());
      final now = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider.overrideWith(
              (_) => WearScreenShape.round,
            ),
            resolvedEventsProvider.overrideWithBuild(
              (ref, _) => [
                ResolvedEvent(
                  id: 1,
                  date: DateTime(now.year, now.month, now.day),
                  number: 1,
                  startTime: '08:00:00',
                  endTime: '08:45:00',
                  subjectId: 10,
                ),
              ],
            ),
          ],
          child: const MaterialApp(home: WearScheduleDetailScreen()),
        ),
      );
      await tester.pump();

      const roundInsetFactor = (1 - 1 / 1.4142135623730951) / 2;
      final scaffoldContentWidth =
          screenSize.width * (1 - 2 * roundInsetFactor);

      final rowWidth = tester
          .getSize(find.byKey(const Key('lesson-item')))
          .width;

      expect(
        rowWidth,
        greaterThanOrEqualTo(scaffoldContentWidth * 0.95),
        reason:
            'row width $rowWidth is less than the scaffold content '
            'width $scaffoldContentWidth, so the list is still applying '
            'its own horizontal padding on top of the scaffold inset',
      );
    },
  );
}
