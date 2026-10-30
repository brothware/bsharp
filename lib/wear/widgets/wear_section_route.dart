import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/wear/screens/wear_attendance_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_bulletins_list_screen.dart';
import 'package:bsharp/wear/screens/wear_grades_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_homework_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_messages_list_screen.dart';
import 'package:bsharp/wear/screens/wear_notes_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_schedule_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_settings_tile.dart';
import 'package:bsharp/wear/screens/wear_tests_detail_screen.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum WearSection {
  schedule(childModeFeature: ChildModeFeature.schedule),
  grades(childModeFeature: ChildModeFeature.grades),
  attendance(childModeFeature: ChildModeFeature.attendance),
  homework,
  tests,
  notes(childModeFeature: ChildModeFeature.notes),
  messages(childModeFeature: ChildModeFeature.messages),
  bulletins(isFullScreen: false),
  settings(isFullScreen: false);

  const WearSection({this.isFullScreen = true, this.childModeFeature});

  final bool isFullScreen;
  final ChildModeFeature? childModeFeature;

  bool isVisibleIn(ChildModeNotifier childMode) => switch (childModeFeature) {
    final feature? => childMode.isFeatureVisible(feature),
    null => true,
  };

  Widget build() => switch (this) {
    WearSection.schedule => const WearScheduleDetailScreen(),
    WearSection.grades => const WearGradesDetailScreen(),
    WearSection.attendance => const WearAttendanceDetailScreen(),
    WearSection.homework => const WearHomeworkDetailScreen(),
    WearSection.tests => const WearTestsDetailScreen(),
    WearSection.notes => const WearNotesDetailScreen(),
    WearSection.messages => const WearMessagesListScreen(),
    WearSection.bulletins => const WearBulletinsListScreen(),
    WearSection.settings => const WearSettingsTile(),
  };
}

bool openWearSection(BuildContext context, WearSection section) {
  final childMode = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(childModeProvider.notifier);
  if (!section.isVisibleIn(childMode)) {
    return false;
  }
  Navigator.of(
    context,
  ).restorablePush(_restoreWearSection, arguments: section.name);
  return true;
}

@pragma('vm:entry-point')
Route<void> _restoreWearSection(BuildContext context, Object? arguments) {
  final section = WearSection.values.byName(arguments! as String);
  return _wearRoute((_) => section.build(), isFullScreen: section.isFullScreen);
}

void pushWearSection(BuildContext context, WidgetBuilder builder) {
  Navigator.of(context).push(_wearRoute(builder, isFullScreen: false));
}

void pushWearScreen(BuildContext context, WidgetBuilder builder) {
  Navigator.of(context).push(_wearRoute(builder, isFullScreen: true));
}

Route<void> _wearRoute(WidgetBuilder builder, {required bool isFullScreen}) {
  if (isFullScreen) {
    return MaterialPageRoute<void>(builder: builder);
  }
  return MaterialPageRoute<void>(
    builder: (context) => WearSwipeDismiss(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: builder(context),
      ),
    ),
  );
}
