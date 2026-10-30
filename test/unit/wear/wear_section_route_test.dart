import 'dart:convert';

import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/screens/wear_grades_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_homework_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_section_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

Future<Widget> _childModeApp({
  required Map<String, bool> config,
  required void Function(BuildContext context) onOpen,
}) async {
  final store = FakeKeyValueStore();
  await store.write(key: 'child_mode_pin', value: '1234');
  await store.write(key: 'child_mode_active', value: 'true');
  await store.write(key: 'child_mode_config', value: jsonEncode(config));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      credentialStorageProvider.overrideWithValue(
        CredentialStorage(store: store),
      ),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.rectangular),
    ],
    child: MaterialApp(
      home: Consumer(
        builder: (context, ref, _) => Scaffold(
          appBar: AppBar(
            title: Text(ref.watch(childModeProvider).mode.name),
          ),
          body: TextButton(
            onPressed: () => onOpen(context),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('openWearSection in child mode', () {
    testWidgets('a section the parent hid does not open', (tester) async {
      bool? opened;
      await tester.pumpWidget(
        await _childModeApp(
          config: {'gradesVisible': false},
          onOpen: (context) =>
              opened = openWearSection(context, WearSection.grades),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(opened, isFalse);
      expect(find.byType(WearGradesDetailScreen), findsNothing);
    });

    testWidgets('a section child mode never hides still opens', (
      tester,
    ) async {
      bool? opened;
      await tester.pumpWidget(
        await _childModeApp(
          config: {'gradesVisible': false},
          onOpen: (context) =>
              opened = openWearSection(context, WearSection.homework),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump();

      expect(opened, isTrue);
      expect(find.byType(WearHomeworkDetailScreen), findsOneWidget);
    });
  });

  test('every section child mode can hide names its feature', () {
    expect(
      {
        for (final section in WearSection.values)
          if (section.childModeFeature != null) section,
      },
      {
        WearSection.schedule,
        WearSection.grades,
        WearSection.attendance,
        WearSection.notes,
        WearSection.messages,
      },
    );
  });
}
