import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/wear/screens/wear_attendance_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_grades_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_homework_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_messages_list_screen.dart';
import 'package:bsharp/wear/screens/wear_notes_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_schedule_detail_screen.dart';
import 'package:bsharp/wear/widgets/wear_section_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

WidgetBuilder? wearScreenBuilderForRoute(String? route) => switch (route) {
  '/grades' => (_) => const WearGradesDetailScreen(),
  '/messages' => (_) => const WearMessagesListScreen(),
  '/schedule' => (_) => const WearScheduleDetailScreen(),
  '/attendance' => (_) => const WearAttendanceDetailScreen(),
  '/homework' => (_) => const WearHomeworkDetailScreen(),
  '/notes' => (_) => const WearNotesDetailScreen(),
  _ => null,
};

class WearNotificationRouter {
  WearNotificationRouter({required this.ref, required this.navigatorKey});

  final WidgetRef ref;
  final GlobalKey<NavigatorState> navigatorKey;

  void handleNotificationTap(NotificationPayload payload) {
    final accountId = payload.accountId;
    final studentId = payload.studentId;

    if (accountId != null && studentId != null) {
      final current = ref.read(activeSelectionProvider).value;
      if (current?.accountId != accountId || current?.studentId != studentId) {
        unawaited(
          ref
              .read(activeSelectionProvider.notifier)
              .select(
                ActiveSelection(accountId: accountId, studentId: studentId),
              ),
        );
      }
    }

    final builder = wearScreenBuilderForRoute(payload.route);
    if (builder == null) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    pushWearScreen(context, builder);
  }
}
