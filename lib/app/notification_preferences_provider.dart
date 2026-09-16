import 'package:bsharp/data/data_sources/local/notification_preferences_store.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/domain/entities/notification_preferences.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationPreferencesNotifier
    extends Notifier<NotificationPreferences> {
  static const _store = NotificationPreferencesStore();

  @override
  NotificationPreferences build() {
    return _store.read(ref.watch(sharedPreferencesProvider));
  }

  Future<void> update(NotificationPreferences prefs) async {
    await _store.write(ref.read(sharedPreferencesProvider), prefs);
    state = prefs;
  }

  Future<void> toggleCategory(ChangeCategory category) async {
    final updated = switch (category) {
      // No switch of their own yet, so there is nothing to flip.
      ChangeCategory.tests || ChangeCategory.bulletins => state,
      ChangeCategory.grades => state.copyWith(
        gradesEnabled: !state.gradesEnabled,
      ),
      ChangeCategory.messages => state.copyWith(
        messagesEnabled: !state.messagesEnabled,
      ),
      ChangeCategory.schedule => state.copyWith(
        scheduleEnabled: !state.scheduleEnabled,
      ),
      ChangeCategory.attendance => state.copyWith(
        attendanceEnabled: !state.attendanceEnabled,
      ),
      ChangeCategory.homework => state.copyWith(
        homeworkEnabled: !state.homeworkEnabled,
      ),
      ChangeCategory.notes => state.copyWith(notesEnabled: !state.notesEnabled),
    };
    await update(updated);
  }

  Future<void> setSyncInterval(int minutes) async {
    if (!NotificationPreferences.validIntervals.contains(minutes)) return;
    await update(state.copyWith(syncIntervalMinutes: minutes));
  }
}

final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
      NotificationPreferencesNotifier.new,
    );
