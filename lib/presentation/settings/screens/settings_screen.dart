import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/app/notification_preferences_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/data/services/translation_service.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/child_mode/screens/child_mode_config_screen.dart';
import 'package:bsharp/app/support_provider.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/presentation/support/tip_jar_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.settings.title)),
      body: ListView(
        children: [
          _SectionHeader(title: t.settings.appearance),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(t.settings.theme),
            subtitle: Text(_themeLabel(themeMode)),
            onTap: () => _showThemeDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(t.settings.language),
            subtitle: Text(_languageSubtitle(ref)),
            onTap: () => _showLanguageDialog(context, ref),
          ),
          const Divider(),
          _SectionHeader(title: t.settings.syncSection),
          const _SyncSection(),
          const Divider(),
          _SectionHeader(title: t.settings.notifications),
          const _NotificationSection(),
          if (ref.watch(isTranslationAvailableProvider)) ...[
            const Divider(),
            _SectionHeader(title: t.translation.settingsTitle),
            const _TranslationSection(),
          ],
          const Divider(),
          _SectionHeader(title: t.settings.childMode),
          ListTile(
            leading: const Icon(Icons.child_care),
            title: Text(t.settings.childModeConfig),
            subtitle: Text(t.settings.childModeConfigSubtitle),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ChildModeConfigScreen(),
              ),
            ),
          ),
          const Divider(),
          _SectionHeader(title: t.settings.account),
          ListTile(
            leading: const Icon(Icons.password),
            title: Text(t.settings.changePassword),
            onTap: () => _showChangePasswordDialog(context, ref),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              t.auth.logout,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => _confirmLogout(context, ref),
          ),
          const Divider(),
          _SectionHeader(title: t.settings.about),
          const _AboutSection(),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => t.settings.themeSystem,
      ThemeMode.light => t.settings.themeLight,
      ThemeMode.dark => t.settings.themeDark,
    };
  }

  String _languageSubtitle(WidgetRef ref) {
    final notifier = ref.read(localeProvider.notifier);
    if (notifier.isSystemLocale) {
      return t.settings.languageSystem;
    }
    return localeDisplayName(ref.read(localeProvider));
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(localeProvider.notifier);

    String localeKey(Locale l) =>
        l.countryCode != null ? '${l.languageCode}_${l.countryCode}' : l.languageCode;

    final currentKey = notifier.isSystemLocale ? 'system' : localeKey(ref.read(localeProvider));

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.settings.chooseLanguage),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: Text(t.settings.languageSystem),
                  leading: Radio<String>(
                    value: 'system',
                    groupValue: currentKey,
                    onChanged: (_) {
                      ref.read(localeProvider.notifier).resetToSystem();
                      Navigator.of(context).pop();
                    },
                  ),
                  onTap: () {
                    ref.read(localeProvider.notifier).resetToSystem();
                    Navigator.of(context).pop();
                  },
                ),
                for (final locale in LocaleNotifier.supportedLocales)
                  ListTile(
                    title: Text(localeDisplayName(locale)),
                    leading: Radio<String>(
                      value: localeKey(locale),
                      groupValue: currentKey,
                      onChanged: (_) {
                        ref.read(localeProvider.notifier).setLocale(locale);
                        Navigator.of(context).pop();
                      },
                    ),
                    onTap: () {
                      ref.read(localeProvider.notifier).setLocale(locale);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.settings.chooseTheme),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in ThemeMode.values)
                ListTile(
                  title: Text(_themeLabel(mode)),
                  leading: Radio<ThemeMode>(
                    value: mode,
                    groupValue: ref.watch(themeModeProvider),
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(value);
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                  onTap: () {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(mode);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.settings.logoutConfirmTitle),
          content: Text(t.settings.logoutConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.common.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authStateProvider.notifier).logout();
              },
              child: Text(t.settings.logoutButton),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.settings.changePassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                decoration: InputDecoration(
                  labelText: t.settings.currentPassword,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(
                  labelText: t.settings.newPassword,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: t.settings.confirmPassword,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.common.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.settings.passwordsMismatch)),
                  );
                  return;
                }
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t.settings.passwordChangePending),
                  ),
                );
              },
              child: Text(t.common.change),
            ),
          ],
        );
      },
    );
  }
}

class _SyncSection extends ConsumerWidget {
  const _SyncSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final lastSync = ref.watch(lastSyncTimeProvider);
    final prefs = ref.watch(notificationPreferencesProvider);

    return Column(
      children: [
        ListTile(
          leading: Icon(
            syncStatus == SyncStatus.syncing
                ? Icons.sync
                : Icons.sync_outlined,
          ),
          title: Text(t.settings.syncNow),
          subtitle: Text(
            lastSync != null
                ? t.settings.syncLast(time: _formatSyncTime(lastSync))
                : t.settings.syncNever,
          ),
          trailing: syncStatus == SyncStatus.syncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: syncStatus == SyncStatus.syncing
              ? null
              : () => ref.read(syncStatusProvider.notifier).sync(),
        ),
        ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: Text(t.settings.syncInterval),
          subtitle: Text(
            t.settings.syncIntervalValue(minutes: prefs.syncIntervalMinutes),
          ),
          onTap: () => _showIntervalPicker(context, ref, prefs),
        ),
      ],
    );
  }

  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return t.common.agoJustNow;
    if (diff.inMinutes < 60) return t.common.agoMinutes(n: diff.inMinutes);
    if (diff.inHours < 24) return t.common.agoHours(n: diff.inHours);
    return '${time.day.toString().padLeft(2, '0')}.'
        '${time.month.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  void _showIntervalPicker(
    BuildContext context,
    WidgetRef ref,
    NotificationPreferences prefs,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.settings.syncIntervalTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final minutes in NotificationPreferences.validIntervals)
                ListTile(
                  title: Text(
                    t.settings.syncIntervalValue(minutes: minutes),
                  ),
                  leading: Radio<int>(
                    value: minutes,
                    groupValue: prefs.syncIntervalMinutes,
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .setSyncInterval(value);
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                  onTap: () {
                    ref
                        .read(notificationPreferencesProvider.notifier)
                        .setSyncInterval(minutes);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationSection extends ConsumerWidget {
  const _NotificationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider);

    return Column(
      children: [
        _NotifToggle(
          title: t.notification.gradesName,
          icon: Icons.grade_outlined,
          value: prefs.gradesEnabled,
          category: ChangeCategory.grades,
        ),
        _NotifToggle(
          title: t.notification.messagesName,
          icon: Icons.mail_outline,
          value: prefs.messagesEnabled,
          category: ChangeCategory.messages,
        ),
        _NotifToggle(
          title: t.notification.scheduleName,
          icon: Icons.calendar_today_outlined,
          value: prefs.scheduleEnabled,
          category: ChangeCategory.schedule,
        ),
        _NotifToggle(
          title: t.notification.attendanceName,
          icon: Icons.event_available_outlined,
          value: prefs.attendanceEnabled,
          category: ChangeCategory.attendance,
        ),
        _NotifToggle(
          title: t.notification.homeworkName,
          icon: Icons.assignment_outlined,
          value: prefs.homeworkEnabled,
          category: ChangeCategory.homework,
        ),
        _NotifToggle(
          title: t.settings.notesNotif,
          icon: Icons.note_outlined,
          value: prefs.notesEnabled,
          category: ChangeCategory.notes,
        ),
      ],
    );
  }
}

class _NotifToggle extends ConsumerWidget {
  const _NotifToggle({
    required this.title,
    required this.icon,
    required this.value,
    required this.category,
  });

  final String title;
  final IconData icon;
  final bool value;
  final ChangeCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      value: value,
      onChanged: (_) => ref
          .read(notificationPreferencesProvider.notifier)
          .toggleCategory(category),
    );
  }
}


class _AboutSection extends ConsumerWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIos = ref.watch(isIosProvider);

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('BSharp'),
          subtitle: ref.watch(packageInfoProvider).whenOrNull(
                    data: (info) =>
                        Text(t.settings.version(version: info.version)),
                  ) ??
              const SizedBox.shrink(),
        ),
        ListTile(
          leading: const Icon(Icons.coffee_outlined),
          title: Text(t.support.title),
          subtitle: Text(t.support.subtitle),
          onTap: () => isIos
              ? showTipJarSheet(context)
              : launchUrl(Uri.parse(supportUrl)),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(t.settings.licenses),
          onTap: () {
            final version = ref.read(packageInfoProvider).valueOrNull?.version;
            showLicensePage(
              context: context,
              applicationName: 'BSharp',
              applicationVersion: version,
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.code),
          title: Text(t.settings.sourceCode),
          subtitle: const Text('GitHub'),
          onTap: () => launchUrl(Uri.parse(sourceCodeUrl)),
        ),
      ],
    );
  }
}

class _TranslationSection extends ConsumerStatefulWidget {
  const _TranslationSection();

  @override
  ConsumerState<_TranslationSection> createState() =>
      _TranslationSectionState();
}

class _TranslationSectionState extends ConsumerState<_TranslationSection> {
  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deeplKey = ref.watch(deeplApiKeyProvider);
    final hasKey = deeplKey.valueOrNull != null;
    final service = ref.watch(translationServiceProvider);
    final engine = service.preferredEngine;

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.translate),
          title: Text(
            engine == TranslationEngine.deepL
                ? t.translation.engineDeepL
                : t.translation.engineOnDevice,
          ),
          subtitle: Text(
            hasKey
                ? t.translation.engineDeepL
                : t.translation.engineOnDevice,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.key),
          title: Text(t.translation.deeplApiKey),
          subtitle: hasKey
              ? const Text('********')
              : null,
          trailing: hasKey
              ? IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final storage = ref.read(credentialStorageProvider);
                    await storage.clearDeeplApiKey();
                    ref.invalidate(deeplApiKeyProvider);
                  },
                )
              : null,
          onTap: () => _showApiKeyDialog(context, ref),
        ),
        if (hasKey)
          ListTile(
            leading: const Icon(Icons.data_usage),
            title: Text(t.translation.deeplUsage(used: '...', limit: '...')),
            onTap: () => _checkUsage(context, ref),
          ),
      ],
    );
  }

  void _showApiKeyDialog(BuildContext context, WidgetRef ref) {
    _apiKeyController.clear();
    _obscureKey = true;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t.translation.deeplApiKey),
          content: TextField(
            controller: _apiKeyController,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureKey ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setDialogState(() => _obscureKey = !_obscureKey),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.common.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final key = _apiKeyController.text.trim();
                if (key.isNotEmpty) {
                  final storage = ref.read(credentialStorageProvider);
                  await storage.saveDeeplApiKey(key);
                  ref.invalidate(deeplApiKeyProvider);
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(t.common.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkUsage(BuildContext context, WidgetRef ref) async {
    final service = ref.read(translationServiceProvider);
    final result = await service.getDeeplUsage();
    if (!context.mounted) return;

    result.when(
      success: (usage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t.translation.deeplUsage(
                used: usage.used.toString(),
                limit: usage.limit.toString(),
              ),
            ),
          ),
        );
      },
      failure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.translation.translationFailed)),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
