import 'dart:async';

import 'package:bsharp/app/app.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../unit/data/credential_storage_test.dart';

class _RecordingNotificationService extends NotificationService {
  final events = <String>[];
  final permissionGate = Completer<bool>();
  bool? treeWasMountedAtPrompt;

  @override
  Future<void> initialize({void Function(NotificationPayload)? onTap}) async {
    events.add('initialize');
  }

  @override
  Future<bool> requestPermission() {
    events.add('requestPermission');
    treeWasMountedAtPrompt = WidgetsBinding.instance.rootElement != null;
    return permissionGate.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<_RecordingNotificationService> pumpApp(WidgetTester tester) async {
    final service = _RecordingNotificationService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(service),
          credentialStorageProvider.overrideWithValue(
            CredentialStorage(store: FakeKeyValueStore()),
          ),
        ],
        child: TranslationProvider(child: const BSharpApp()),
      ),
    );
    return service;
  }

  testWidgets('the ui is mounted before permissions are requested', (
    tester,
  ) async {
    final service = await pumpApp(tester);

    expect(
      service.treeWasMountedAtPrompt,
      isTrue,
      reason: 'prompting before runApp leaves the user on a blank screen',
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('permissions are requested once the first frame is up', (
    tester,
  ) async {
    final service = await pumpApp(tester);

    await tester.pump();

    expect(service.events, ['initialize', 'requestPermission']);
  });

  testWidgets('the app stays on screen while the prompt is unanswered', (
    tester,
  ) async {
    final service = await pumpApp(tester);
    await tester.pump();

    expect(service.permissionGate.isCompleted, isFalse);
    expect(find.byType(MaterialApp), findsOneWidget);

    service.permissionGate.complete(true);
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
