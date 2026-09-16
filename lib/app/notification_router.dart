import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/providers/messages_providers.dart';
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
  ChangeCategory.tests: AppRoutes.tests,
  ChangeCategory.bulletins: AppRoutes.bulletins,
};

class NotificationRouter {
  NotificationRouter({required this.ref, required this.routerProvider});

  final WidgetRef ref;
  final GoRouter? Function() routerProvider;

  /// What the tapped notification was about, kept until the sync it triggered
  /// brings in the item itself.
  ChangeCategory? _awaitingReveal;

  /// Which item, when the notification named one.
  int? _awaitingItemId;

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

    _awaitingReveal = category;
    _awaitingItemId = payload.itemId;
    router.go(route);

    // The notification named the item, so there is nothing to work out: open it
    // if it is already here, and otherwise wait for the sync to fetch it.
    if (_reveal(router, category, payload.itemId)) {
      _awaitingReveal = null;
      _awaitingItemId = null;
    }
  }

  /// The sync a tapped notification set off has finished. If it brought in
  /// exactly one item of the kind that was tapped, that item is what the
  /// person was reaching for, so open it. Anything else and the section they
  /// are already looking at is the honest answer.
  void handleSyncCompleted(ChangeSet changes) {
    final category = _awaitingReveal;
    final namedId = _awaitingItemId;
    _awaitingReveal = null;
    _awaitingItemId = null;
    if (category == null) return;

    final router = routerProvider();
    if (router == null) return;

    if (namedId != null) {
      _reveal(router, category, namedId);
      return;
    }

    // Nothing named an item, so the sync has to answer it: one thing of that
    // kind arrived means that is the one, anything else and the section stands.
    final arrived = changes.byCategory(category);
    if (arrived.length != 1) return;
    _reveal(router, category, arrived.single.entityId);
  }

  /// Opens the item itself, and reports whether it managed to.
  bool _reveal(GoRouter router, ChangeCategory category, int? itemId) {
    if (itemId == null) return false;
    if (category != ChangeCategory.messages) return false;

    final message = ref
        .read(inboxProvider)
        .where((m) => m.id == itemId)
        .firstOrNull;
    if (message == null) return false;

    unawaited(router.push(AppRoutes.messageView, extra: message));
    return true;
  }
}
