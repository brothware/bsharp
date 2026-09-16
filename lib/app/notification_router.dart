import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Where each kind of news lives. Providers say what a notification is about;
/// only the app knows which screen that is.
const _sectionRoutes = <ChangeCategory, String>{
  ChangeCategory.messages: AppRoutes.messages,
  ChangeCategory.grades: AppRoutes.grades,
  ChangeCategory.attendance: AppRoutes.attendance,
  ChangeCategory.notes: AppRoutes.notes,
  ChangeCategory.schedule: AppRoutes.schedule,
  ChangeCategory.homework: AppRoutes.homework,
};

class NotificationRouter {
  NotificationRouter({required this.ref, required this.routerProvider});

  final WidgetRef ref;
  final GoRouter? Function() routerProvider;

  void handleNotificationTap(NotificationPayload payload) {
    final router = routerProvider();
    if (router == null) return;

    final category = payload.category;
    if (category == null) return;

    final route = _sectionRoutes[category];
    if (route == null) return;

    final accountId = payload.accountId;
    final studentId = payload.studentId;

    if (accountId != null && studentId != null) {
      final currentSelection = ref.read(activeSelectionProvider).value;
      if (currentSelection?.accountId != accountId ||
          currentSelection?.studentId != studentId) {
        unawaited(
          ref
              .read(activeSelectionProvider.notifier)
              .select(
                ActiveSelection(accountId: accountId, studentId: studentId),
              ),
        );
      }
    }

    router.go(route);
  }
}
