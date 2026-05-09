import 'dart:convert';
import 'dart:io';

import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalFcmNotification {
  const LocalFcmNotification({
    required this.title,
    required this.body,
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    required this.route,
    this.triggersSync = true,
  });

  final String title;
  final String body;
  final String channelId;
  final String channelName;
  final String channelDescription;
  final String route;
  final bool triggersSync;
}

class NotificationPayload {
  const NotificationPayload({this.accountId, this.studentId, this.route});

  factory NotificationPayload.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return NotificationPayload(
      accountId: map['accountId'] as String?,
      studentId: map['studentId'] as int?,
      route: map['route'] as String?,
    );
  }

  final String? accountId;
  final int? studentId;
  final String? route;

  String toJson() => jsonEncode({
    'accountId': accountId,
    'studentId': studentId,
    'route': route,
  });
}

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _unexcusedChannelId = 'unexcused_absences';
  static const _unexcusedNotificationId = 100;

  Future<void> initialize({void Function(NotificationPayload)? onTap}) async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('ic_notification');
    const iosSettings = DarwinInitializationSettings();
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: onTap != null
          ? (response) {
              final payload = response.payload;
              if (payload != null && payload.isNotEmpty) {
                onTap(NotificationPayload.fromJson(payload));
              }
            }
          : null,
    );
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

  Future<bool> handleForegroundFcmMessage(LocalFcmNotification? spec) async {
    if (spec == null) return false;
    if (!_initialized) await initialize();
    await showFcmNotification(spec);
    return spec.triggersSync;
  }

  Future<void> showFcmNotification(LocalFcmNotification spec) async {
    if (!_initialized) return;

    final androidDetails = AndroidNotificationDetails(
      spec.channelId,
      spec.channelName,
      channelDescription: spec.channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    final payload = NotificationPayload(route: spec.route).toJson();

    await _plugin.show(
      id: spec.title.hashCode,
      title: spec.title,
      body: spec.body,
      notificationDetails: details,
      payload: payload,
    );
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
