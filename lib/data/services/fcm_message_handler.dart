import 'package:bsharp/data/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.data}');
  final data = FcmNotificationData.fromMessage(message);
  if (data.title.isEmpty) return;
  final service = NotificationService();
  await service.initialize();
  await service.showFcmNotification(data);
}
