import 'package:bsharp/domain/change_detection.dart';

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

  static const validIntervals = [15, 30, 45, 60];

  bool isCategoryEnabled(ChangeCategory category) {
    return switch (category) {
      ChangeCategory.grades => gradesEnabled,
      ChangeCategory.messages => messagesEnabled,
      ChangeCategory.schedule => scheduleEnabled,
      ChangeCategory.attendance => attendanceEnabled,
      ChangeCategory.homework => homeworkEnabled,
      ChangeCategory.notes => notesEnabled,
      // No switch of their own yet, so they are always delivered rather than
      // silently riding on an unrelated one.
      ChangeCategory.tests || ChangeCategory.bulletins => true,
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
}
