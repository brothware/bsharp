import 'package:bsharp/domain/school_data_provider.dart';
import 'package:flutter/material.dart';

Future<void> runMailAction({
  required ScaffoldMessengerState messenger,
  required String failureText,
  required Future<void> Function() action,
}) async {
  try {
    await action();
  } on MessagingException catch (error, stackTrace) {
    debugPrint('Mail action failed: $error\n$stackTrace');
    if (messenger.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(failureText)));
    }
  }
}
