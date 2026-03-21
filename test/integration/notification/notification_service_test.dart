@TestOn('vm')
library;

import 'package:bsharp/app/notification_preferences_provider.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/domain/change_detection.dart';
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
    test('single new grade shows notification with correct payload', () async {
      await service.initialize();

      const changes = ChangeSet(
        changes: [
          ChangeItem(category: ChangeCategory.grades, title: 'New grade'),
        ],
        accountId: 'acc-1',
        studentId: 6541,
      );
      const prefs = NotificationPreferences();

      await service.showChanges(changes, prefs);

      final captured = verify(
        () => mockPlugin.show(
          id: captureAny(named: 'id'),
          title: captureAny(named: 'title'),
          body: captureAny(named: 'body'),
          notificationDetails: captureAny(named: 'notificationDetails'),
          payload: captureAny(named: 'payload'),
        ),
      ).captured;

      expect(captured[0], ChangeCategory.grades.index);
      expect(captured[4], contains('"accountId":"acc-1"'));
      expect(captured[4], contains('"route":"/grades"'));
    });

    test('3 grades + 2 messages shows two grouped notifications', () async {
      await service.initialize();

      const changes = ChangeSet(
        changes: [
          ChangeItem(category: ChangeCategory.grades, title: 'G1'),
          ChangeItem(category: ChangeCategory.grades, title: 'G2'),
          ChangeItem(category: ChangeCategory.grades, title: 'G3'),
          ChangeItem(category: ChangeCategory.messages, title: 'M1'),
          ChangeItem(category: ChangeCategory.messages, title: 'M2'),
        ],
      );
      const prefs = NotificationPreferences();

      await service.showChanges(changes, prefs);

      verify(
        () => mockPlugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).called(2);
    });

    test('grades disabled in prefs skips grade notifications', () async {
      await service.initialize();

      const changes = ChangeSet(
        changes: [
          ChangeItem(category: ChangeCategory.grades, title: 'G1'),
        ],
      );
      const prefs = NotificationPreferences(gradesEnabled: false);

      await service.showChanges(changes, prefs);

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

    test('empty ChangeSet shows no notifications', () async {
      await service.initialize();

      const changes = ChangeSet();
      const prefs = NotificationPreferences();

      await service.showChanges(changes, prefs);

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
