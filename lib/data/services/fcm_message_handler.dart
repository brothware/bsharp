import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

LocalFcmNotification? parseFcmMessageWithKnownProviders(RemoteMessage message) {
  for (final provider in allKnownProviders()) {
    final spec = provider.parseFcmMessage(message);
    if (spec != null) return spec;
  }
  return null;
}

@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.data}');
  final spec = parseFcmMessageWithKnownProviders(message);
  if (spec == null) return;
  final service = NotificationService();
  await service.initialize();
  await service.showFcmNotification(spec);
}
