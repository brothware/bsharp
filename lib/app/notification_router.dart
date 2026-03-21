import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationRouter {
  NotificationRouter({required this.ref, required this.routerProvider});

  final Ref ref;
  final GoRouter Function() routerProvider;

  void handleNotificationTap(NotificationPayload payload) {
    final route = payload.route;
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

    routerProvider().go(route);
  }
}
