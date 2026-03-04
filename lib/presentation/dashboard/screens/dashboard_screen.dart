import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/responsive.dart';
import 'package:bsharp/presentation/dashboard/widgets/current_lesson_card.dart';
import 'package:bsharp/presentation/dashboard/widgets/recent_grades_card.dart';
import 'package:bsharp/presentation/dashboard/widgets/unexcused_absences_card.dart';
import 'package:bsharp/presentation/dashboard/widgets/unread_messages_card.dart';
import 'package:bsharp/presentation/dashboard/widgets/upcoming_homework_card.dart';
import 'package:bsharp/presentation/dashboard/widgets/upcoming_tests_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final lastSync = ref.watch(lastSyncTimeProvider);
    final size = screenSizeOf(context);
    final provider = ref.watch(activeDataProviderProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(syncStatusProvider.notifier).sync(),
      child: CustomScrollView(
        slivers: [
          if (syncStatus == SyncStatus.failed)
            SliverToBoxAdapter(child: _SyncFailedBanner(ref: ref)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _buildLastSyncInfo(context, lastSync),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: size == ScreenSize.phone
                ? _buildPhoneLayout(provider)
                : _buildWideLayout(provider),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildLastSyncInfo(BuildContext context, DateTime? lastSync) {
    final text = lastSync != null
        ? t.dashboard.lastSync(time: _formatTime(lastSync))
        : t.dashboard.neverSynced;
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return t.common.agoJustNow;
    if (diff.inMinutes < 60) return t.common.agoMinutes(n: diff.inMinutes);
    if (diff.inHours < 24) return t.common.agoHours(n: diff.inHours);
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildPhoneLayout(SchoolDataProvider provider) {
    final cards = _buildCards(provider);
    return SliverList.list(children: cards);
  }

  Widget _buildWideLayout(SchoolDataProvider provider) {
    final cards = _buildCards(provider);
    return SliverList.list(children: cards);
  }

  List<Widget> _buildCards(SchoolDataProvider provider) {
    final hasSchedule = provider.supports(DataProviderCapability.schedule);
    final hasMessages = provider.supports(DataProviderCapability.messages);
    final hasAttendance = provider.supports(DataProviderCapability.attendance);
    final hasGrades = provider.supports(DataProviderCapability.grades);
    final hasHomework = provider.supports(DataProviderCapability.homework);
    final hasTests = provider.supports(DataProviderCapability.tests);

    return [
      if (hasSchedule) const CurrentLessonCard(),
      if (hasSchedule) const SizedBox(height: 8),
      if (hasMessages) const UnreadMessagesCard(),
      if (hasAttendance) const UnexcusedAbsencesCard(),
      if (hasGrades) const RecentGradesCard(),
      if (hasHomework || hasTests) const SizedBox(height: 8),
      if (hasHomework && hasTests)
        const _PairedRow(
          left: UpcomingHomeworkCard(),
          right: UpcomingTestsCard(),
        )
      else if (hasHomework)
        const UpcomingHomeworkCard()
      else if (hasTests)
        const UpcomingTestsCard(),
    ];
  }
}

class _SyncFailedBanner extends StatelessWidget {
  const _SyncFailedBanner({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.sync_problem,
            size: 16,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t.dashboard.syncFailed,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(syncStatusProvider.notifier).sync(),
            child: Text(t.common.retry),
          ),
        ],
      ),
    );
  }
}

class _PairedRow extends StatelessWidget {
  const _PairedRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 4),
        Expanded(child: right),
      ],
    );
  }
}
