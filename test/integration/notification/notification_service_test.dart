@TestOn('vm')
library;

import 'package:bsharp/data/services/notification_service.dart';
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
}
