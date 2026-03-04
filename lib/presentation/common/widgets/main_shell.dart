import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/responsive.dart';
import 'package:bsharp/presentation/common/widgets/child_switcher.dart';
import 'package:bsharp/presentation/messages/providers/messages_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _phoneVisibleCount = 4;

class MainShell extends ConsumerWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = screenSizeOf(context);
    final notifier = ref.read(childModeProvider.notifier);
    ref.watch(childModeProvider);

    final provider = ref.watch(activeDataProviderProvider);
    final allItems = _allDestinations();
    final visible = <_IndexedNavItem>[];
    for (var i = 0; i < allItems.length; i++) {
      final feature = allItems[i].feature;
      final cap = allItems[i].capability;
      final featureOk = feature == null || notifier.isFeatureVisible(feature);
      final capOk = cap == null || provider.supports(cap);
      if (featureOk && capOk) {
        visible.add(_IndexedNavItem(branchIndex: i, item: allItems[i]));
      }
    }

    final currentBranch = navigationShell.currentIndex;
    final visibleIndex = visible.indexWhere(
      (e) => e.branchIndex == currentBranch,
    );
    if (visibleIndex == -1 && visible.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigationShell.goBranch(visible.first.branchIndex);
      });
    }
    final effectiveVisibleIndex = visibleIndex == -1 ? 0 : visibleIndex;

    final syncStatus = ref.watch(syncStatusProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final messagesVisible =
        notifier.isFeatureVisible(ChildModeFeature.messages) &&
        provider.supports(DataProviderCapability.messages);
    final settingsVisible = notifier.isFeatureVisible(
      ChildModeFeature.settings,
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: _buildTitle(context, ref),
        actions: [
          if (provider.requiresCredentials) ...[
            if (syncStatus == SyncStatus.syncing)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: t.settings.sync,
                onPressed: () => ref.read(syncStatusProvider.notifier).sync(),
              ),
          ],
          if (messagesVisible)
            IconButton(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: const Icon(Icons.mail_outline),
              ),
              onPressed: () => context.push(AppRoutes.messages),
            ),
          if (settingsVisible)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push(AppRoutes.settings),
            ),
        ],
      ),
      body: size == ScreenSize.phone
          ? navigationShell
          : Row(
              children: [
                SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          kToolbarHeight,
                    ),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        selectedIndex: effectiveVisibleIndex,
                        onDestinationSelected: (i) =>
                            _onTap(visible[i].branchIndex),
                        labelType: size == ScreenSize.desktop
                            ? null
                            : NavigationRailLabelType.all,
                        extended: size == ScreenSize.desktop,
                        destinations: [
                          for (final entry in visible)
                            NavigationRailDestination(
                              icon: Icon(entry.item.icon),
                              selectedIcon: Icon(entry.item.selectedIcon),
                              label: Text(entry.item.label),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: navigationShell),
              ],
            ),
      bottomNavigationBar: size == ScreenSize.phone
          ? _PhoneBottomNav(
              items: visible,
              currentVisibleIndex: effectiveVisibleIndex,
              onTap: (i) => _onTap(visible[i].branchIndex),
            )
          : null,
    );
  }

  Widget _buildTitle(BuildContext context, WidgetRef ref) {
    return const ChildSwitcher();
  }

  void _onTap(int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  static List<_NavItem> _allDestinations() {
    return [
      _NavItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: t.nav.dashboard,
      ),
      _NavItem(
        icon: Icons.calendar_today_outlined,
        selectedIcon: Icons.calendar_today,
        label: t.nav.schedule,
        feature: ChildModeFeature.schedule,
        capability: DataProviderCapability.schedule,
      ),
      _NavItem(
        icon: Icons.grade_outlined,
        selectedIcon: Icons.grade,
        label: t.nav.grades,
        feature: ChildModeFeature.grades,
        capability: DataProviderCapability.grades,
      ),
      _NavItem(
        icon: Icons.check_circle_outline,
        selectedIcon: Icons.check_circle,
        label: t.nav.attendance,
        feature: ChildModeFeature.attendance,
        capability: DataProviderCapability.attendance,
      ),
      _NavItem(
        icon: Icons.assignment_outlined,
        selectedIcon: Icons.assignment,
        label: t.nav.homework,
        capability: DataProviderCapability.homework,
      ),
      _NavItem(
        icon: Icons.note_outlined,
        selectedIcon: Icons.note,
        label: t.nav.notes,
        feature: ChildModeFeature.notes,
        capability: DataProviderCapability.notes,
      ),
      _NavItem(
        icon: Icons.quiz_outlined,
        selectedIcon: Icons.quiz,
        label: t.nav.tests,
        capability: DataProviderCapability.tests,
      ),
      _NavItem(
        icon: Icons.campaign_outlined,
        selectedIcon: Icons.campaign,
        label: t.nav.bulletins,
        capability: DataProviderCapability.bulletins,
      ),
      _NavItem(
        icon: Icons.history_outlined,
        selectedIcon: Icons.history,
        label: t.nav.changelog,
        capability: DataProviderCapability.changelog,
      ),
    ];
  }
}

class _PhoneBottomNav extends StatelessWidget {
  const _PhoneBottomNav({
    required this.items,
    required this.currentVisibleIndex,
    required this.onTap,
  });

  final List<_IndexedNavItem> items;
  final int currentVisibleIndex;
  final void Function(int) onTap;

  int get _effectiveIndex => currentVisibleIndex < _phoneVisibleCount
      ? currentVisibleIndex
      : _phoneVisibleCount;

  @override
  Widget build(BuildContext context) {
    final primary = items.take(_phoneVisibleCount).toList();
    final overflow = items.skip(_phoneVisibleCount).toList();

    return NavigationBar(
      selectedIndex: _effectiveIndex,
      onDestinationSelected: (index) {
        if (index < _phoneVisibleCount) {
          onTap(index);
        } else {
          _showOverflowSheet(context, overflow);
        }
      },
      destinations: [
        for (final entry in primary)
          NavigationDestination(
            icon: Icon(entry.item.icon),
            selectedIcon: Icon(entry.item.selectedIcon),
            label: entry.item.label,
          ),
        if (overflow.isNotEmpty)
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            selectedIcon: const Icon(Icons.more_horiz),
            label: t.nav.more,
          ),
      ],
    );
  }

  void _showOverflowSheet(
    BuildContext context,
    List<_IndexedNavItem> overflow,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < overflow.length; i++)
              ListTile(
                leading: Icon(
                  currentVisibleIndex == _phoneVisibleCount + i
                      ? overflow[i].item.selectedIcon
                      : overflow[i].item.icon,
                  color: currentVisibleIndex == _phoneVisibleCount + i
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(
                  overflow[i].item.label,
                  style: currentVisibleIndex == _phoneVisibleCount + i
                      ? TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        )
                      : null,
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onTap(_phoneVisibleCount + i);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _IndexedNavItem {
  const _IndexedNavItem({required this.branchIndex, required this.item});

  final int branchIndex;
  final _NavItem item;
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.feature,
    this.capability,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final ChildModeFeature? feature;
  final DataProviderCapability? capability;
}
