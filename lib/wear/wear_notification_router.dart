import 'package:bsharp/app/notification_tap_handler.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/wear/screens/wear_attendance_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_bulletins_list_screen.dart';
import 'package:bsharp/wear/screens/wear_grades_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_homework_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_message_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_messages_list_screen.dart';
import 'package:bsharp/wear/screens/wear_notes_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_schedule_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_tests_detail_screen.dart';
import 'package:bsharp/wear/widgets/wear_section_route.dart';
import 'package:flutter/material.dart';

WidgetBuilder? wearScreenBuilderForCategory(ChangeCategory? category) =>
    switch (category) {
      ChangeCategory.grades => (_) => const WearGradesDetailScreen(),
      ChangeCategory.messages => (_) => const WearMessagesListScreen(),
      ChangeCategory.schedule => (_) => const WearScheduleDetailScreen(),
      ChangeCategory.attendance => (_) => const WearAttendanceDetailScreen(),
      ChangeCategory.homework => (_) => const WearHomeworkDetailScreen(),
      ChangeCategory.notes => (_) => const WearNotesDetailScreen(),
      ChangeCategory.bulletins => (_) => const WearBulletinsListScreen(),
      ChangeCategory.tests => (_) => const WearTestsDetailScreen(),
      null => null,
    };

class WearNotificationRouter extends NotificationTapHandler {
  WearNotificationRouter({required super.ref, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  bool openSection(ChangeCategory category) {
    final builder = wearScreenBuilderForCategory(category);
    if (builder == null) return false;

    final context = navigatorKey.currentContext;
    if (context == null) return false;

    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    pushWearScreen(context, builder);
    return true;
  }

  @override
  bool openMessage(PocztaMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return false;

    pushWearScreen(context, (_) => WearMessageDetailScreen(message: message));
    return true;
  }
}
