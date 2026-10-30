import 'package:bsharp/app/notification_tap_handler.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/wear/screens/wear_message_detail_screen.dart';
import 'package:bsharp/wear/widgets/wear_section_route.dart';
import 'package:flutter/material.dart';

WearSection? wearSectionForCategory(ChangeCategory? category) =>
    switch (category) {
      ChangeCategory.grades => WearSection.grades,
      ChangeCategory.messages => WearSection.messages,
      ChangeCategory.schedule => WearSection.schedule,
      ChangeCategory.attendance => WearSection.attendance,
      ChangeCategory.homework => WearSection.homework,
      ChangeCategory.notes => WearSection.notes,
      ChangeCategory.bulletins => WearSection.bulletins,
      ChangeCategory.tests => WearSection.tests,
      null => null,
    };

class WearNotificationRouter extends NotificationTapHandler {
  WearNotificationRouter({required super.ref, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  bool openSection(ChangeCategory category) {
    final section = wearSectionForCategory(category);
    if (section == null) {
      return false;
    }

    final context = navigatorKey.currentContext;
    if (context == null) return false;

    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    return openWearSection(context, section);
  }

  @override
  bool openMessage(PocztaMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return false;

    pushWearScreen(context, (_) => WearMessageDetailScreen(message: message));
    return true;
  }
}
