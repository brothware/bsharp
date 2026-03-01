import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';

class NotificationPreferences {
  const NotificationPreferences({
    this.gradesEnabled = true,
    this.messagesEnabled = true,
    this.scheduleEnabled = true,
    this.attendanceEnabled = false,
    this.homeworkEnabled = true,
    this.notesEnabled = true,
    this.syncIntervalMinutes = 30,
  });

  final bool gradesEnabled;
  final bool messagesEnabled;
  final bool scheduleEnabled;
  final bool attendanceEnabled;
  final bool homeworkEnabled;
  final bool notesEnabled;
  final int syncIntervalMinutes;

  bool isCategoryEnabled(ChangeCategory category) {
    return switch (category) {
      ChangeCategory.grades => gradesEnabled,
      ChangeCategory.messages => messagesEnabled,
      ChangeCategory.schedule => scheduleEnabled,
      ChangeCategory.attendance => attendanceEnabled,
      ChangeCategory.homework => homeworkEnabled,
      ChangeCategory.notes => notesEnabled,
    };
  }

  NotificationPreferences copyWith({
    bool? gradesEnabled,
    bool? messagesEnabled,
    bool? scheduleEnabled,
    bool? attendanceEnabled,
    bool? homeworkEnabled,
    bool? notesEnabled,
    int? syncIntervalMinutes,
  }) {
    return NotificationPreferences(
      gradesEnabled: gradesEnabled ?? this.gradesEnabled,
      messagesEnabled: messagesEnabled ?? this.messagesEnabled,
      scheduleEnabled: scheduleEnabled ?? this.scheduleEnabled,
      attendanceEnabled: attendanceEnabled ?? this.attendanceEnabled,
      homeworkEnabled: homeworkEnabled ?? this.homeworkEnabled,
      notesEnabled: notesEnabled ?? this.notesEnabled,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
    );
  }

  static const validIntervals = [15, 30, 45, 60];
}

final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
  NotificationPreferencesNotifier.new,
);

class NotificationPreferencesNotifier extends Notifier<NotificationPreferences> {
  static const _prefix = 'notif_';
  static const _gradesKey = '${_prefix}grades';
  static const _messagesKey = '${_prefix}messages';
  static const _scheduleKey = '${_prefix}schedule';
  static const _attendanceKey = '${_prefix}attendance';
  static const _homeworkKey = '${_prefix}homework';
  static const _notesKey = '${_prefix}notes';
  static const _intervalKey = '${_prefix}interval';

  @override
  NotificationPreferences build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return NotificationPreferences(
      gradesEnabled: prefs.getBool(_gradesKey) ?? true,
      messagesEnabled: prefs.getBool(_messagesKey) ?? true,
      scheduleEnabled: prefs.getBool(_scheduleKey) ?? true,
      attendanceEnabled: prefs.getBool(_attendanceKey) ?? false,
      homeworkEnabled: prefs.getBool(_homeworkKey) ?? true,
      notesEnabled: prefs.getBool(_notesKey) ?? true,
      syncIntervalMinutes: prefs.getInt(_intervalKey) ?? 30,
    );
  }

  Future<void> update(NotificationPreferences prefs) async {
    final sp = ref.read(sharedPreferencesProvider);
    await Future.wait([
      sp.setBool(_gradesKey, prefs.gradesEnabled),
      sp.setBool(_messagesKey, prefs.messagesEnabled),
      sp.setBool(_scheduleKey, prefs.scheduleEnabled),
      sp.setBool(_attendanceKey, prefs.attendanceEnabled),
      sp.setBool(_homeworkKey, prefs.homeworkEnabled),
      sp.setBool(_notesKey, prefs.notesEnabled),
      sp.setInt(_intervalKey, prefs.syncIntervalMinutes),
    ]);
    state = prefs;
  }

  Future<void> toggleCategory(ChangeCategory category) async {
    final updated = switch (category) {
      ChangeCategory.grades =>
        state.copyWith(gradesEnabled: !state.gradesEnabled),
      ChangeCategory.messages =>
        state.copyWith(messagesEnabled: !state.messagesEnabled),
      ChangeCategory.schedule =>
        state.copyWith(scheduleEnabled: !state.scheduleEnabled),
      ChangeCategory.attendance =>
        state.copyWith(attendanceEnabled: !state.attendanceEnabled),
      ChangeCategory.homework =>
        state.copyWith(homeworkEnabled: !state.homeworkEnabled),
      ChangeCategory.notes =>
        state.copyWith(notesEnabled: !state.notesEnabled),
    };
    await update(updated);
  }

  Future<void> setSyncInterval(int minutes) async {
    if (!NotificationPreferences.validIntervals.contains(minutes)) return;
    await update(state.copyWith(syncIntervalMinutes: minutes));
  }
}
