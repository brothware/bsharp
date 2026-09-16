import 'package:bsharp/domain/entities/notification_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the notification switches are kept.
///
/// Both the settings screen and the code that decides whether to post a
/// notification read them from here, including the background isolate, which
/// has no providers of its own to ask.
class NotificationPreferencesStore {
  const NotificationPreferencesStore();

  static const _prefix = 'notif_';
  static const _gradesKey = '${_prefix}grades';
  static const _messagesKey = '${_prefix}messages';
  static const _scheduleKey = '${_prefix}schedule';
  static const _attendanceKey = '${_prefix}attendance';
  static const _homeworkKey = '${_prefix}homework';
  static const _notesKey = '${_prefix}notes';
  static const _intervalKey = '${_prefix}interval';

  NotificationPreferences read(SharedPreferences prefs) {
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

  Future<NotificationPreferences> load() async {
    return read(await SharedPreferences.getInstance());
  }

  Future<void> write(
    SharedPreferences prefs,
    NotificationPreferences preferences,
  ) async {
    await Future.wait([
      prefs.setBool(_gradesKey, preferences.gradesEnabled),
      prefs.setBool(_messagesKey, preferences.messagesEnabled),
      prefs.setBool(_scheduleKey, preferences.scheduleEnabled),
      prefs.setBool(_attendanceKey, preferences.attendanceEnabled),
      prefs.setBool(_homeworkKey, preferences.homeworkEnabled),
      prefs.setBool(_notesKey, preferences.notesEnabled),
      prefs.setInt(_intervalKey, preferences.syncIntervalMinutes),
    ]);
  }
}
