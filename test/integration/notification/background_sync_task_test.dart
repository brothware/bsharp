@TestOn('vm')
@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:bsharp/core/network/api_client_factory.dart';
import 'package:bsharp/data/services/background_sync_task.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

Map<String, Object> _cacheValues({
  List<ProviderAccount>? accounts,
  String? accountId,
  int? studentId,
  Map<String, Object>? extra,
}) {
  final values = <String, Object>{...?extra};
  if (accounts != null) {
    values['bg_cache_accounts'] = jsonEncode(
      accounts.map((a) => a.toJson()).toList(),
    );
  }
  if (accountId != null && studentId != null) {
    values['bg_cache_active_selection'] = jsonEncode({
      'accountId': accountId,
      'studentId': studentId,
    });
  }
  return values;
}

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.en);
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
  });

  group('BackgroundSyncTask', () {
    test('no active account returns false with no notifications', () async {
      final mockPlugin = MockFlutterLocalNotificationsPlugin();

      when(
        () => mockPlugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      SharedPreferences.setMockInitialValues({});
      final task = BackgroundSyncTask(
        notificationService: NotificationService(plugin: mockPlugin),
        prefsFactory: SharedPreferences.getInstance,
        rescheduleOnComplete: false,
      );

      final result = await task.execute();

      expect(result, isFalse);
      verifyNever(
        () => mockPlugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('no active selection returns false', () async {
      SharedPreferences.setMockInitialValues(
        _cacheValues(
          accounts: const [
            ProviderAccount(
              id: 'test-id',
              providerType: 'mobireg',
              slug: 'test-school',
              login: 'testuser',
              passwordHash: 'abc123',
              schoolName: 'Test School',
              students: [
                AccountStudent(id: 1, name: 'Jan', surname: 'Kowalski'),
              ],
            ),
          ],
        ),
      );

      final mockPlugin = MockFlutterLocalNotificationsPlugin();
      final task = BackgroundSyncTask(
        notificationService: NotificationService(plugin: mockPlugin),
        prefsFactory: SharedPreferences.getInstance,
        rescheduleOnComplete: false,
      );

      final result = await task.execute();

      expect(result, isFalse);
    });

    test('active account but missing account data returns false', () async {
      SharedPreferences.setMockInitialValues(
        _cacheValues(
          accounts: const [],
          accountId: 'nonexistent',
          studentId: 1,
        ),
      );

      final mockPlugin = MockFlutterLocalNotificationsPlugin();
      final task = BackgroundSyncTask(
        notificationService: NotificationService(plugin: mockPlugin),
        prefsFactory: SharedPreferences.getInstance,
        rescheduleOnComplete: false,
      );

      final result = await task.execute();

      expect(result, isFalse);
    });
  });

  group('BackgroundSyncTask E2E against mock server', () {
    const mockBaseUrl = 'http://localhost:8090';
    late bool mockAvailable;

    setUpAll(() async {
      try {
        final socket = await Socket.connect(
          'localhost',
          8090,
          timeout: const Duration(seconds: 1),
        );
        socket.destroy();
        mockAvailable = true;
      } on Object {
        mockAvailable = false;
      }
    });

    Future<MockFlutterLocalNotificationsPlugin> createMockPlugin() async {
      final mockPlugin = MockFlutterLocalNotificationsPlugin();
      when(
        () => mockPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => mockPlugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockPlugin.cancel(id: any(named: 'id')),
      ).thenAnswer((_) async {});
      return mockPlugin;
    }

    BackgroundSyncTask createTask({
      required MockFlutterLocalNotificationsPlugin mockPlugin,
      required Future<SharedPreferences> Function() prefsFactory,
    }) {
      return BackgroundSyncTask(
        notificationService: NotificationService(plugin: mockPlugin),
        prefsFactory: prefsFactory,
        apiClientFactory:
            ({
              required school,
              required parentLogin,
              required parentPassHash,
            }) => ApiClientFactory(
              school: school,
              parentLogin: parentLogin,
              parentPassHash: parentPassHash,
            ),
        rescheduleOnComplete: false,
      );
    }

    Map<String, Object> defaultCacheValues([
      Map<String, Object>? extra,
    ]) {
      return _cacheValues(
        accounts: const [
          ProviderAccount(
            id: 'bg-test-account',
            providerType: 'mobireg',
            slug: 'osm-wroclaw',
            login: 'dsliwa',
            passwordHash: 'testhash',
            schoolName: 'OSM Wrocław',
            students: [
              AccountStudent(id: 6541, name: 'Dawid', surname: 'Śliwa'),
            ],
          ),
        ],
        accountId: 'bg-test-account',
        studentId: 6541,
        extra: extra,
      );
    }

    Future<void> resetScenarios() async {
      final dio = Dio(BaseOptions(baseUrl: mockBaseUrl));
      await dio.post<dynamic>('/test/reset');
      dio.close();
    }

    test(
      'first sync completes successfully but fires no notifications',
      () async {
        if (!mockAvailable) {
          markTestSkipped('mobireg-mock not running on localhost:8090');
          return;
        }

        await resetScenarios();
        SharedPreferences.setMockInitialValues(defaultCacheValues());
        final mockPlugin = await createMockPlugin();
        final task = createTask(
          mockPlugin: mockPlugin,
          prefsFactory: SharedPreferences.getInstance,
        );

        final result = await task.execute();

        expect(result, isTrue);
        verifyNever(
          () => mockPlugin.show(
            id: ChangeCategory.grades.index,
            title: any(named: 'title'),
            body: any(named: 'body'),
            notificationDetails: any(named: 'notificationDetails'),
            payload: any(named: 'payload'),
          ),
        );
      },
    );

    test(
      'second sync with same data fires no notifications',
      () async {
        if (!mockAvailable) {
          markTestSkipped('mobireg-mock not running on localhost:8090');
          return;
        }

        await resetScenarios();
        SharedPreferences.setMockInitialValues(defaultCacheValues());
        final mockPlugin = await createMockPlugin();

        final task1 = createTask(
          mockPlugin: mockPlugin,
          prefsFactory: SharedPreferences.getInstance,
        );
        final firstResult = await task1.execute();
        expect(firstResult, isTrue);

        final task2 = createTask(
          mockPlugin: mockPlugin,
          prefsFactory: SharedPreferences.getInstance,
        );
        final secondResult = await task2.execute();
        expect(secondResult, isTrue);

        verifyNever(
          () => mockPlugin.show(
            id: ChangeCategory.grades.index,
            title: any(named: 'title'),
            body: any(named: 'body'),
            notificationDetails: any(named: 'notificationDetails'),
            payload: any(named: 'payload'),
          ),
        );
      },
    );

    test(
      'second sync with new grade fires grade notification with payload',
      () async {
        if (!mockAvailable) {
          markTestSkipped('mobireg-mock not running on localhost:8090');
          return;
        }

        await resetScenarios();
        SharedPreferences.setMockInitialValues(defaultCacheValues());
        final mockPlugin = await createMockPlugin();

        final task1 = createTask(
          mockPlugin: mockPlugin,
          prefsFactory: SharedPreferences.getInstance,
        );
        await task1.execute();

        final dio = Dio(BaseOptions(baseUrl: mockBaseUrl));
        await dio.post<dynamic>(
          '/test/scenario',
          data: jsonEncode({
            'school': 'osm-wroclaw',
            'extraMarks': [
              {
                'action': 'I',
                'id': 8099,
                'mark_groups_id': 9001,
                'mark_scales_id': 10006,
                'pupil_users_id': 9001,
                'teacher_users_id': 3001,
                'mark_value': 6.0,
                'comments': null,
                'weight': 3,
                'get_date': '2026-03-20',
                'add_time': '2026-03-20 12:00:00',
                'modified': 0,
                'events_id': null,
              },
            ],
          }),
          options: Options(contentType: 'application/json'),
        );
        dio.close();

        final task2 = createTask(
          mockPlugin: mockPlugin,
          prefsFactory: SharedPreferences.getInstance,
        );
        await task2.execute();

        final verificationResult = verify(
          () => mockPlugin.show(
            id: ChangeCategory.grades.index,
            title: any(named: 'title'),
            body: any(named: 'body'),
            notificationDetails: any(named: 'notificationDetails'),
            payload: captureAny(named: 'payload'),
          ),
        )..called(1);

        final payload = verificationResult.captured.first as String;
        final decoded = jsonDecode(payload) as Map<String, dynamic>;
        expect(decoded['accountId'], 'bg-test-account');
        expect(decoded['studentId'], 6541);
        expect(decoded['route'], '/grades');

        await resetScenarios();
      },
    );

    test(
      'disabled category does not fire notification even with new data',
      () async {
        if (!mockAvailable) {
          markTestSkipped('mobireg-mock not running on localhost:8090');
          return;
        }

        await resetScenarios();
        SharedPreferences.setMockInitialValues(
          defaultCacheValues({'notif_grades': false}),
        );
        final mockPlugin = await createMockPlugin();

        final task1 = createTask(
          mockPlugin: mockPlugin,
          prefsFactory: SharedPreferences.getInstance,
        );
        await task1.execute();

        final dio = Dio(BaseOptions(baseUrl: mockBaseUrl));
        await dio.post<dynamic>(
          '/test/scenario',
          data: jsonEncode({
            'school': 'osm-wroclaw',
            'extraMarks': [
              {
                'action': 'I',
                'id': 8098,
                'mark_groups_id': 9001,
                'mark_scales_id': 10005,
                'pupil_users_id': 9001,
                'teacher_users_id': 3001,
                'mark_value': 5.0,
                'comments': null,
                'weight': 2,
                'get_date': '2026-03-20',
                'add_time': '2026-03-20 13:00:00',
                'modified': 0,
                'events_id': null,
              },
            ],
          }),
          options: Options(contentType: 'application/json'),
        );
        dio.close();

        final task2 = createTask(
          mockPlugin: mockPlugin,
          prefsFactory: SharedPreferences.getInstance,
        );
        await task2.execute();

        verifyNever(
          () => mockPlugin.show(
            id: ChangeCategory.grades.index,
            title: any(named: 'title'),
            body: any(named: 'body'),
            notificationDetails: any(named: 'notificationDetails'),
            payload: any(named: 'payload'),
          ),
        );

        await resetScenarios();
      },
    );

    test(
      'school-b account gets notifications with correct account context',
      () async {
        if (!mockAvailable) {
          markTestSkipped('mobireg-mock not running on localhost:8090');
          return;
        }

        await resetScenarios();
        SharedPreferences.setMockInitialValues(
          _cacheValues(
            accounts: const [
              ProviderAccount(
                id: 'school-b-account',
                providerType: 'mobireg',
                slug: 'sp5-krakow',
                login: 'mwisniewska',
                passwordHash: 'testhash',
                schoolName: 'SP5 Kraków',
                students: [
                  AccountStudent(
                    id: 7001,
                    name: 'Maja',
                    surname: 'Wiśniewska',
                  ),
                ],
              ),
            ],
            accountId: 'school-b-account',
            studentId: 7001,
          ),
        );

        final mockPlugin = await createMockPlugin();

        final task1 = createTask(
          mockPlugin: mockPlugin,
          prefsFactory: SharedPreferences.getInstance,
        );
        await task1.execute();

        final dio = Dio(BaseOptions(baseUrl: mockBaseUrl));
        await dio.post<dynamic>(
          '/test/scenario',
          data: jsonEncode({
            'school': 'sp5-krakow',
            'extraMarks': [
              {
                'action': 'I',
                'id': 9099,
                'mark_groups_id': 10001,
                'mark_scales_id': 10006,
                'pupil_users_id': 9501,
                'teacher_users_id': 4001,
                'mark_value': 6.0,
                'comments': null,
                'weight': 3,
                'get_date': '2026-03-20',
                'add_time': '2026-03-20 14:00:00',
                'modified': 0,
                'events_id': null,
              },
            ],
          }),
          options: Options(contentType: 'application/json'),
        );
        dio.close();

        final task2 = createTask(
          mockPlugin: mockPlugin,
          prefsFactory: SharedPreferences.getInstance,
        );
        await task2.execute();

        final verificationResult = verify(
          () => mockPlugin.show(
            id: ChangeCategory.grades.index,
            title: any(named: 'title'),
            body: any(named: 'body'),
            notificationDetails: any(named: 'notificationDetails'),
            payload: captureAny(named: 'payload'),
          ),
        )..called(1);

        final payload = verificationResult.captured.first as String;
        final decoded = jsonDecode(payload) as Map<String, dynamic>;
        expect(decoded['accountId'], 'school-b-account');
        expect(decoded['studentId'], 7001);
        expect(decoded['route'], '/grades');

        await resetScenarios();
      },
    );
  });
}
