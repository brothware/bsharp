import 'dart:io';

import 'package:bsharp/app/notification_preferences_provider.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _gradesChannelId = 'grades';
  static const _messagesChannelId = 'messages';
  static const _scheduleChannelId = 'schedule';
  static const _attendanceChannelId = 'attendance';
  static const _homeworkChannelId = 'homework';
  static const _notesChannelId = 'notes';
  static const _unexcusedChannelId = 'unexcused_absences';
  static const _unexcusedNotificationId = 100;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }
    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  Future<void> showChanges(
    ChangeSet changes,
    NotificationPreferences prefs,
  ) async {
    if (!_initialized || changes.isEmpty) return;

    final grouped = changes.grouped;

    for (final entry in grouped.entries) {
      if (!prefs.isCategoryEnabled(entry.key)) continue;
      if (entry.value.isEmpty) continue;

      await _showCategoryNotification(entry.key, entry.value);
    }
  }

  Future<void> _showCategoryNotification(
    ChangeCategory category,
    List<ChangeItem> items,
  ) async {
    final config = _channelConfig(category);
    final count = items.length;

    final androidDetails = AndroidNotificationDetails(
      config.channelId,
      config.channelName,
      channelDescription: config.channelDescription,
      number: count,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    final title = count == 1
        ? items.first.title
        : '${config.channelName}: $count';

    final body = count == 1
        ? items.first.subtitle ?? ''
        : items.take(3).map((i) => i.title).join(', ');

    await _plugin.show(
      id: category.index,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  _ChannelConfig _channelConfig(ChangeCategory category) {
    return switch (category) {
      ChangeCategory.grades => _ChannelConfig(
        channelId: _gradesChannelId,
        channelName: t.notification.gradesName,
        channelDescription: t.notification.gradesDescription,
      ),
      ChangeCategory.messages => _ChannelConfig(
        channelId: _messagesChannelId,
        channelName: t.notification.messagesName,
        channelDescription: t.notification.messagesDescription,
      ),
      ChangeCategory.schedule => _ChannelConfig(
        channelId: _scheduleChannelId,
        channelName: t.notification.scheduleName,
        channelDescription: t.notification.scheduleDescription,
      ),
      ChangeCategory.attendance => _ChannelConfig(
        channelId: _attendanceChannelId,
        channelName: t.notification.attendanceName,
        channelDescription: t.notification.attendanceDescription,
      ),
      ChangeCategory.homework => _ChannelConfig(
        channelId: _homeworkChannelId,
        channelName: t.notification.homeworkName,
        channelDescription: t.notification.homeworkDescription,
      ),
      ChangeCategory.notes => _ChannelConfig(
        channelId: _notesChannelId,
        channelName: t.notification.notesName,
        channelDescription: t.notification.notesDescription,
      ),
    };
  }

  Future<void> showUnexcusedAbsenceAlert(int count) async {
    if (!_initialized || count == 0) {
      await _plugin.cancel(id: _unexcusedNotificationId);
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      _unexcusedChannelId,
      t.notification.unexcusedAbsenceName,
      channelDescription: t.notification.unexcusedAbsenceDescription,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: _unexcusedNotificationId,
      title: t.notification.unexcusedAbsenceTitle,
      body: t.notification.unexcusedAbsenceBody(count: count),
      notificationDetails: details,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

class _ChannelConfig {
  const _ChannelConfig({
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
  });

  final String channelId;
  final String channelName;
  final String channelDescription;
}
