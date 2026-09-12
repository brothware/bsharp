import 'dart:async';

import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/app/providers/attendance_providers.dart';
import 'package:bsharp/app/providers/dashboard_providers.dart';
import 'package:bsharp/app/providers/grades_providers.dart';
import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/app/providers/more_providers.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/domain/attendance_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/screens/wear_attendance_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_bulletins_list_screen.dart';
import 'package:bsharp/wear/screens/wear_dashboard.dart';
import 'package:bsharp/wear/screens/wear_grades_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_homework_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_messages_list_screen.dart';
import 'package:bsharp/wear/screens/wear_notes_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_schedule_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_settings_tile.dart';
import 'package:bsharp/wear/screens/wear_tests_detail_screen.dart';
import 'package:bsharp/wear/wear_summary_utils.dart';
import 'package:bsharp/wear/widgets/wear_launcher_row.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:bsharp/wear/widgets/wear_section_route.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar.dart';

const _testsWindowDays = 7;

class _WearSection {
  const _WearSection({
    required this.icon,
    required this.title,
    required this.summary,
    required this.builder,
    this.isFullScreen = true,
  });

  final IconData icon;
  final String title;
  final String summary;
  final WidgetBuilder builder;
  final bool isFullScreen;
}

class WearHome extends ConsumerStatefulWidget {
  const WearHome({super.key});

  @override
  ConsumerState<WearHome> createState() => _WearHomeState();
}

class _WearHomeState extends ConsumerState<WearHome> {
  late final ScrollController _controller;
  final GlobalKey _lastRowKey = GlobalKey();
  double _lastRowBottomPadding = 0;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _measureLastRowBottomPadding(double viewportHeight) {
    final renderObject = _lastRowKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final lastRowHeight = renderObject.size.height;
    final halfRowGap = viewportHeight / 2 - lastRowHeight / 2;
    final target = halfRowGap.isNegative ? 0.0 : halfRowGap;
    if ((target - _lastRowBottomPadding).abs() > 0.5) {
      setState(() => _lastRowBottomPadding = target);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(childModeProvider);
    final notifier = ref.read(childModeProvider.notifier);

    final todayLessons = ref.watch(todayLessonsProvider);
    final newGrades = ref.watch(newGradeIdsProvider).length;
    final attendanceStats = ref.watch(attendanceStatsProvider);
    final homeworkDue = ref.watch(upcomingHomeworkProvider).length;
    final testsThisWeek = testsWithinDays(
      ref.watch(upcomingTestsProvider),
      _testsWindowDays,
    );
    final unreadMessages = ref.watch(unreadCountProvider);
    final unreadAnnouncements = ref.watch(unreadBulletinsCountProvider);
    final lastSync = ref.watch(lastSyncTimeProvider);

    final sections = <_WearSection>[
      if (notifier.isFeatureVisible(ChildModeFeature.schedule))
        _WearSection(
          icon: Icons.calendar_today,
          title: t.nav.schedule,
          summary: t.wearLauncher.lessonsCount(count: todayLessons.length),
          builder: (_) => const WearScheduleDetailScreen(),
        ),
      if (notifier.isFeatureVisible(ChildModeFeature.grades))
        _WearSection(
          icon: Icons.grade,
          title: t.nav.grades,
          summary: t.wearLauncher.gradesNewCount(count: newGrades),
          builder: (_) => const WearGradesDetailScreen(),
        ),
      if (notifier.isFeatureVisible(ChildModeFeature.attendance))
        _WearSection(
          icon: Icons.event_available,
          title: t.nav.attendance,
          summary: attendanceStats.totalLessons == 0
              ? t.common.noData
              : attendancePercentLabel(attendanceStats.presentPercent),
          builder: (_) => const WearAttendanceDetailScreen(),
        ),
      _WearSection(
        icon: Icons.assignment,
        title: t.homework.title,
        summary: t.wearLauncher.homeworkDueCount(count: homeworkDue),
        builder: (_) => const WearHomeworkDetailScreen(),
      ),
      _WearSection(
        icon: Icons.quiz_outlined,
        title: t.tests.title,
        summary: t.wearLauncher.testsWeekCount(count: testsThisWeek),
        builder: (_) => const WearTestsDetailScreen(),
      ),
      if (notifier.isFeatureVisible(ChildModeFeature.notes))
        _WearSection(
          icon: Icons.sticky_note_2_outlined,
          title: t.nav.notes,
          summary: t.wearLauncher.annotationsSummary,
          builder: (_) => const WearNotesDetailScreen(),
        ),
      if (notifier.isFeatureVisible(ChildModeFeature.messages))
        _WearSection(
          icon: Icons.mail_outline,
          title: t.nav.messages,
          summary: t.wearLauncher.messagesUnreadCount(count: unreadMessages),
          builder: (_) => const WearMessagesListScreen(),
        ),
      _WearSection(
        icon: Icons.campaign_outlined,
        title: t.nav.bulletins,
        summary: t.wearLauncher.announcementsNewCount(
          count: unreadAnnouncements,
        ),
        builder: (_) => const WearBulletinsListScreen(),
        isFullScreen: false,
      ),
      _WearSection(
        icon: Icons.settings,
        title: t.settings.title,
        summary: lastSync == null
            ? t.wearLauncher.settingsNeverSynced
            : t.wearLauncher.settingsSyncedAt(time: _formatTime(lastSync)),
        builder: (_) => const WearSettingsTile(),
        isFullScreen: false,
      ),
    ];

    return WearSwipeDismiss(
      onDismiss: () => unawaited(SystemNavigator.pop()),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: WearScaffold(
          child: LayoutBuilder(
            builder: (context, constraints) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _measureLastRowBottomPadding(constraints.maxHeight),
              );
              return WearOsScrollbar(
                controller: _controller,
                child: CustomScrollView(
                  controller: _controller,
                  scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
                  slivers: [
                    const SliverToBoxAdapter(child: WearDashboard()),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final section = sections[index];
                        final isLastRow = index == sections.length - 1;
                        return WearLauncherRow(
                          measureKey: isLastRow ? _lastRowKey : null,
                          icon: section.icon,
                          title: section.title,
                          summary: section.summary,
                          scrollController: _controller,
                          onTap: () => section.isFullScreen
                              ? pushWearScreen(context, section.builder)
                              : pushWearSection(context, section.builder),
                        );
                      }, childCount: sections.length),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: _lastRowBottomPadding),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
