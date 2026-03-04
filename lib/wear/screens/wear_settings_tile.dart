import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/screens/wear_child_mode_screen.dart';
import 'package:bsharp/wear/screens/wear_language_screen.dart';
import 'package:bsharp/wear/screens/wear_pin_entry.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_tile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearSettingsTile extends ConsumerWidget {
  const WearSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shape = ref.watch(wearScreenShapeProvider).requireValue;
    final childState = ref.watch(childModeProvider);

    return Column(
      children: [
        WearTileHeader(icon: Icons.settings, title: t.settings.title),
        Expanded(
          child: ListView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(8, 0, 8, wearListBottomInset(shape)),
            children: [
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
                  onTap: () => _showThemeDialog(context, ref),
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
                  onTap: () {
                    ref.read(syncStatusProvider.notifier).sync();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(t.settings.syncing),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                _WearSettingsItem(
                  icon: Icons.logout,
                  label: t.settings.logoutButton,
                  iconColor: Theme.of(context).colorScheme.error,
                  onTap: () => _showLogoutDialog(context, ref),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final current = ref.read(themeModeProvider);
    final theme = Theme.of(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in ThemeMode.values)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setThemeMode(mode);
                    Navigator.of(dialogContext).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _themeIcon(mode),
                          size: 18,
                          color: mode == current
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _themeLabel(mode),
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
            ],
          ),
        ),
      ),
    );
  }

  IconData _themeIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => Icons.brightness_auto,
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
    };
  }

  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => t.settings.themeSystem,
      ThemeMode.light => t.settings.themeLight,
      ThemeMode.dark => t.settings.themeDark,
    };
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.settings.logoutConfirmTitle),
        content: Text(t.settings.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(authStateProvider.notifier).logout();
            },
            child: Text(t.settings.logoutButton),
          ),
        ],
      ),
    );
  }
}

class _WearSettingsItem extends StatelessWidget {
  const _WearSettingsItem({
    required this.icon,
    required this.label,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: iconColor ?? theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}
