import 'dart:async';

import 'package:bsharp/app/notification_tap_handler.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/domain/entities/poczta.dart';
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

class NotificationRouter extends NotificationTapHandler {
  NotificationRouter({required super.ref, required this.routerProvider});

  final GoRouter? Function() routerProvider;

  @override
  bool openSection(ChangeCategory category) {
    final router = routerProvider();
    final route = _sectionRoutes[category];
    if (router == null || route == null) return false;

    router.go(route);
    return true;
  }

  @override
  bool openMessage(PocztaMessage message) {
    final router = routerProvider();
    if (router == null) return false;

    unawaited(router.push(AppRoutes.messageView, extra: message));
    return true;
  }
}
