import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/domain/theme_labels.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/screens/wear_child_mode_screen.dart';
import 'package:bsharp/wear/screens/wear_language_screen.dart';
import 'package:bsharp/wear/screens/wear_pin_entry.dart';
import 'package:bsharp/wear/screens/wear_setup_screen.dart';
import 'package:bsharp/wear/screens/wear_student_picker.dart';
import 'package:bsharp/wear/widgets/wear_confirmation.dart';
import 'package:bsharp/wear/widgets/wear_list_item.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:bsharp/wear/widgets/wear_status_line.dart';
import 'package:bsharp/wear/widgets/wear_tile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearSettingsTile extends ConsumerStatefulWidget {
  const WearSettingsTile({super.key});

  @override
  ConsumerState<WearSettingsTile> createState() => _WearSettingsTileState();
}

class _WearSettingsTileState extends ConsumerState<WearSettingsTile> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final childState = ref.watch(childModeProvider);
    final allEntries = ref.watch(allStudentsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return WearScaffold(
      scrollController: _scrollController,
      child: Column(
        children: [
          WearTileHeader(icon: Icons.settings, title: t.settings.title),
          Expanded(
            child: Builder(
              builder: (context) => ListView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                padding: wearListPadding(WearDisplayScope.of(context)),
                children: wearScaledChildren(_scrollController, [
                  if (childState.isChildMode)
                    _WearSettingsItem(
                      icon: Icons.child_care,
                      label: t.childMode.childModeActive,
                      iconColor: Colors.orange,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const WearPinEntry(),
                        ),
                      ),
                    )
                  else ...[
                    if (allEntries.length > 1)
                      _WearSettingsItem(
                        icon: Icons.people,
                        label: t.accounts.switchStudent,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const WearStudentPicker(),
                          ),
                        ),
                      ),
                    _WearSettingsItem(
                      icon: Icons.person_add_alt,
                      label: t.accounts.addAccount,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const WearSetupScreen(addingAnother: true),
                        ),
                      ),
                    ),
                    _WearSettingsItem(
                      icon: Icons.child_care,
                      label: t.childMode.title,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const WearChildModeScreen(),
                        ),
                      ),
                    ),
                    _WearSettingsItem(
                      icon: Icons.brightness_6,
                      label: t.settings.theme,
                      trailing: Text(
                        themeModeLabel(themeMode),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const _WearThemeScreen(),
                        ),
                      ),
                    ),
                    _WearSettingsItem(
                      icon: Icons.language,
                      label: t.settings.language,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const WearLanguageScreen(),
                        ),
                      ),
                    ),
                    _WearSettingsItem(
                      icon: Icons.sync,
                      label: t.settings.sync,
                      trailing: const WearStatusLine(),
                      onTap: () => unawaited(
                        ref.read(syncStatusProvider.notifier).sync(),
                      ),
                    ),
                    _WearSettingsItem(
                      icon: Icons.logout,
                      label: t.settings.logoutButton,
                      iconColor: Theme.of(context).colorScheme.error,
                      onTap: () => _confirmLogout(context, ref),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final confirmed = await showWearConfirmation(
      context,
      icon: Icons.logout,
      question: t.settings.logoutConfirmBody,
      confirmLabel: t.settings.logoutButton,
      isDestructive: true,
    );
    if (!confirmed) return;

    await ref.read(authStateProvider.notifier).logout();

    // Settings was pushed over the app, and signing out only swaps what the
    // app shows underneath. Without this the confirmation closes onto the
    // settings of an account that no longer exists.
    navigator.popUntil((route) => route.isFirst);
  }
}

class _WearThemeScreen extends ConsumerStatefulWidget {
  const _WearThemeScreen();

  @override
  ConsumerState<_WearThemeScreen> createState() => _WearThemeScreenState();
}

class _WearThemeScreenState extends ConsumerState<_WearThemeScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: WearScaffold(
        scrollController: _scrollController,
        child: ListView(
          controller: _scrollController,
          children: wearScaledChildren(_scrollController, [
            for (final mode in wearThemeModes)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  unawaited(
                    ref.read(themeModeProvider.notifier).setThemeMode(mode),
                  );
                  Navigator.of(context).pop();
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          themeModeIcon(mode),
                          size: 18,
                          color: mode == current
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            themeModeLabel(mode),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: mode == current
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ),
                        if (mode == current)
                          Icon(
                            Icons.check,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _WearSettingsItem extends StatelessWidget {
  const _WearSettingsItem({
    required this.icon,
    required this.label,
    this.iconColor,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: iconColor ?? theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(label, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
              if (trailing case final trailing?)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 26),
                  child: trailing,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
