@TestOn('vm')
library;

import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/domain/entities/notification_preferences.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late NotificationService service;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.en);
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
  });

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    service = NotificationService(plugin: mockPlugin);

    when(
      () => mockPlugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
        onDidReceiveBackgroundNotificationResponse: any(
          named: 'onDidReceiveBackgroundNotificationResponse',
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
  });

  group('NotificationService', () {
    test(
      'showUnexcusedAbsenceAlert with count shows ongoing notification',
      () async {
        await service.initialize();

        await service.showUnexcusedAbsenceAlert(3);

        verify(
          () => mockPlugin.show(
            id: 100,
            title: any(named: 'title'),
            body: any(named: 'body'),
            notificationDetails: any(named: 'notificationDetails'),
            payload: any(named: 'payload'),
          ),
        ).called(1);
      },
    );

    test('showUnexcusedAbsenceAlert with zero cancels notification', () async {
      await service.initialize();

      await service.showUnexcusedAbsenceAlert(0);

      verify(() => mockPlugin.cancel(id: 100)).called(1);
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
  });

  group('category switches', () {
    LocalFcmNotification specOf(ChangeCategory category) =>
        LocalFcmNotification(
          title: 'Tytul',
          body: 'Tresc',
          channelId: 'grades',
          channelName: 'Grades',
          channelDescription: 'Grades',
          category: category,
        );

    NotificationService serviceWith(NotificationPreferences prefs) =>
        NotificationService(
          plugin: mockPlugin,
          loadPreferences: () async => prefs,
        );

    test('shows a notification the person left switched on', () async {
      final service = serviceWith(const NotificationPreferences());
      await service.initialize();

      await service.showFcmNotification(specOf(ChangeCategory.grades));

      verify(
        () => mockPlugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });

    test('says nothing about a category switched off', () async {
      final service = serviceWith(
        const NotificationPreferences(gradesEnabled: false),
      );
      await service.initialize();

      await service.showFcmNotification(specOf(ChangeCategory.grades));

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

    test('still syncs for a category switched off', () async {
      final service = serviceWith(
        const NotificationPreferences(gradesEnabled: false),
      );
      await service.initialize();

      final shouldSync = await service.handleForegroundFcmMessage(
        specOf(ChangeCategory.grades),
      );

      expect(shouldSync, isTrue);
    });

    test('shows a notification it cannot place', () async {
      final service = serviceWith(
        const NotificationPreferences(gradesEnabled: false),
      );
      await service.initialize();

      await service.showFcmNotification(
        const LocalFcmNotification(
          title: 'Tytul',
          body: 'Tresc',
          channelId: 'general',
          channelName: 'General',
          channelDescription: 'General',
          category: null,
        ),
      );

      verify(
        () => mockPlugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });
  });
}
