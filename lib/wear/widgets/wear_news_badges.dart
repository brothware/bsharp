import 'package:bsharp/app/providers/grades_providers.dart';
import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/app/providers/more_providers.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/screens/wear_bulletins_list_screen.dart';
import 'package:bsharp/wear/screens/wear_grades_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_messages_list_screen.dart';
import 'package:bsharp/wear/screens/wear_notes_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_tests_detail_screen.dart';
import 'package:bsharp/wear/wear_summary_utils.dart';
import 'package:bsharp/wear/widgets/wear_section_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _maxVisibleBadges = 4;
const _testsWindowDays = 7;

class _Badge {
  const _Badge({
    required this.icon,
    required this.count,
    required this.openSection,
    this.isFullScreen = true,
  });

  final IconData icon;
  final int count;
  final WidgetBuilder openSection;
  final bool isFullScreen;
}

class WearNewsBadges extends ConsumerWidget {
  const WearNewsBadges({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadMessages = ref.watch(unreadCountProvider);
    final newGrades = ref.watch(newGradeIdsProvider).length;
    final upcomingTests = testsWithinDays(
      ref.watch(upcomingTestsProvider),
      _testsWindowDays,
    );
    final remarksCount = ref.watch(unreadRemarksCountProvider);
    final praisesCount = ref.watch(unreadPraisesCountProvider);
    final infoCount = ref.watch(unreadInfoCountProvider);
    final unreadAnnotations = remarksCount + praisesCount + infoCount;
    final unreadAnnouncements = ref.watch(unreadBulletinsCountProvider);

    final badges = <_Badge>[
      if (unreadMessages > 0)
        _Badge(
          icon: Icons.mail_outline,
          count: unreadMessages,
          openSection: (_) => const WearMessagesListScreen(),
        ),
      if (newGrades > 0)
        _Badge(
          icon: Icons.grade,
          count: newGrades,
          openSection: (_) => const WearGradesDetailScreen(),
        ),
      if (upcomingTests > 0)
        _Badge(
          icon: Icons.quiz_outlined,
          count: upcomingTests,
          openSection: (_) => const WearTestsDetailScreen(),
        ),
      if (unreadAnnotations > 0)
        _Badge(
          icon: Icons.sticky_note_2_outlined,
          count: unreadAnnotations,
          openSection: (_) => const WearNotesDetailScreen(),
        ),
      if (unreadAnnouncements > 0)
        _Badge(
          icon: Icons.campaign_outlined,
          count: unreadAnnouncements,
          openSection: (_) => const WearBulletinsListScreen(),
          isFullScreen: false,
        ),
    ];

    if (badges.isEmpty) return const SizedBox.shrink();

    final visible = badges.take(_maxVisibleBadges).toList();
    final overflowCount = badges.length > _maxVisibleBadges
        ? badges.skip(_maxVisibleBadges).fold<int>(0, (a, b) => a + b.count)
        : 0;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final badge in visible)
          _WearBadgeChip(
            icon: badge.icon,
            label: '${badge.count}',
            onTap: () => badge.isFullScreen
                ? pushWearScreen(context, badge.openSection)
                : pushWearSection(context, badge.openSection),
          ),
        if (overflowCount > 0)
          _WearBadgeChip(
            icon: Icons.more_horiz,
            label: t.wearDashboard.moreBadge(n: overflowCount),
            onTap: null,
          ),
      ],
    );
  }
}

class _WearBadgeChip extends StatelessWidget {
  const _WearBadgeChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primaryContainer,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.onPrimaryContainer),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
