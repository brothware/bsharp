import 'package:bsharp/app/notification_preferences_provider.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NotificationPreferences', () {
    test('defaults are correct', () {
      const prefs = NotificationPreferences();
      expect(prefs.gradesEnabled, isTrue);
      expect(prefs.messagesEnabled, isTrue);
      expect(prefs.scheduleEnabled, isTrue);
      expect(prefs.attendanceEnabled, isFalse);
      expect(prefs.homeworkEnabled, isTrue);
      expect(prefs.notesEnabled, isTrue);
      expect(prefs.syncIntervalMinutes, 30);
    });

    test('isCategoryEnabled maps all categories', () {
      const prefs = NotificationPreferences();
      expect(prefs.isCategoryEnabled(ChangeCategory.grades), isTrue);
      expect(prefs.isCategoryEnabled(ChangeCategory.messages), isTrue);
      expect(prefs.isCategoryEnabled(ChangeCategory.schedule), isTrue);
      expect(prefs.isCategoryEnabled(ChangeCategory.attendance), isFalse);
      expect(prefs.isCategoryEnabled(ChangeCategory.homework), isTrue);
      expect(prefs.isCategoryEnabled(ChangeCategory.notes), isTrue);
    });

    test('copyWith overrides selected fields', () {
      const prefs = NotificationPreferences();
      final updated = prefs.copyWith(
        attendanceEnabled: true,
        gradesEnabled: false,
        syncIntervalMinutes: 60,
      );
      expect(updated.attendanceEnabled, isTrue);
      expect(updated.gradesEnabled, isFalse);
      expect(updated.messagesEnabled, isTrue);
      expect(updated.syncIntervalMinutes, 60);
    });

    test('validIntervals contains expected values', () {
      expect(NotificationPreferences.validIntervals, [15, 30, 45, 60]);
    });
  });

  group('NotificationPreferencesNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    });

    test('loads defaults from empty preferences', () {
      final prefs = container.read(notificationPreferencesProvider);
      expect(prefs.gradesEnabled, isTrue);
      expect(prefs.syncIntervalMinutes, 30);
    });

    test('toggleCategory flips the value', () async {
      final notifier = container.read(notificationPreferencesProvider.notifier);
      await notifier.toggleCategory(ChangeCategory.grades);

      final prefs = container.read(notificationPreferencesProvider);
      expect(prefs.gradesEnabled, isFalse);
    });

    test('toggleCategory twice restores original value', () async {
      final notifier = container.read(notificationPreferencesProvider.notifier);
      await notifier.toggleCategory(ChangeCategory.grades);
      await notifier.toggleCategory(ChangeCategory.grades);

      final prefs = container.read(notificationPreferencesProvider);
      expect(prefs.gradesEnabled, isTrue);
    });

    test('setSyncInterval updates interval', () async {
      final notifier = container.read(notificationPreferencesProvider.notifier);
      await notifier.setSyncInterval(60);

      final prefs = container.read(notificationPreferencesProvider);
      expect(prefs.syncIntervalMinutes, 60);
    });

    test('setSyncInterval rejects invalid value', () async {
      final notifier = container.read(notificationPreferencesProvider.notifier);
      await notifier.setSyncInterval(20);

      final prefs = container.read(notificationPreferencesProvider);
      expect(prefs.syncIntervalMinutes, 30);
    });

    test('persists preferences to SharedPreferences', () async {
      final notifier = container.read(notificationPreferencesProvider.notifier);
      await notifier.toggleCategory(ChangeCategory.messages);

      final sp = container.read(sharedPreferencesProvider);
      expect(sp.getBool('notif_messages'), isFalse);
    });
  });
}
