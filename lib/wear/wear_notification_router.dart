import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/wear/screens/wear_attendance_tile.dart';
import 'package:bsharp/wear/screens/wear_grades_tile.dart';
import 'package:bsharp/wear/screens/wear_homework_tile.dart';
import 'package:bsharp/wear/screens/wear_messages_tile.dart';
import 'package:bsharp/wear/screens/wear_notes_tile.dart';
import 'package:bsharp/wear/screens/wear_schedule_tile.dart';
import 'package:bsharp/wear/widgets/wear_section_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

WidgetBuilder? wearScreenBuilderForRoute(String? route) => switch (route) {
  '/grades' => (_) => const WearGradesTile(),
  '/messages' => (_) => const WearMessagesTile(),
  '/schedule' => (_) => const WearScheduleTile(),
  '/attendance' => (_) => const WearAttendanceTile(),
  '/homework' => (_) => const WearHomeworkTile(),
  '/notes' => (_) => const WearNotesTile(),
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
    pushWearSection(context, builder);
  }
}
