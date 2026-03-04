import 'dart:async';

import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/child_mode/screens/pin_entry_screen.dart';
import 'package:bsharp/presentation/child_mode/screens/pin_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChildModeConfigScreen extends ConsumerWidget {
  const ChildModeConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(childModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.childMode.title)),
      body: ListView(
        children: [
          _SectionHeader(title: t.childMode.pin),
          if (state.isPinSet) ...[
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(t.childMode.pinSet),
              subtitle: Text(t.childMode.pinAvailable),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(t.childMode.changePin),
              onTap: () => _navigateToPinSetup(context),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
              title: Text(
                t.childMode.removePin,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () => _confirmRemovePin(context, ref),
            ),
          ] else
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(t.childMode.setPin),
              subtitle: Text(t.childMode.removePinRequired),
              onTap: () => _navigateToPinSetup(context),
            ),
          const Divider(),
          _SectionHeader(title: t.childMode.visibleFeatures),
          Text(
            '  ${t.childMode.visibleFeaturesSubtitle}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          _FeatureToggle(
            title: t.schedule.title,
            icon: Icons.calendar_today_outlined,
            value: state.config.scheduleVisible,
            onChanged: (v) =>
                _updateFeature(ref, state.config.copyWith(scheduleVisible: v)),
          ),
          _FeatureToggle(
            title: t.grades.title,
            icon: Icons.grade_outlined,
            value: state.config.gradesVisible,
            onChanged: (v) =>
                _updateFeature(ref, state.config.copyWith(gradesVisible: v)),
          ),
          _FeatureToggle(
            title: t.attendance.title,
            icon: Icons.event_available_outlined,
            value: state.config.attendanceVisible,
            onChanged: (v) => _updateFeature(
              ref,
              state.config.copyWith(attendanceVisible: v),
            ),
          ),
          _FeatureToggle(
            title: t.messages.title,
            icon: Icons.mail_outline,
            value: state.config.messagesVisible,
            onChanged: (v) =>
                _updateFeature(ref, state.config.copyWith(messagesVisible: v)),
          ),
          _FeatureToggle(
            title: t.notes.title,
            icon: Icons.note_outlined,
            value: state.config.notesVisible,
            onChanged: (v) =>
                _updateFeature(ref, state.config.copyWith(notesVisible: v)),
          ),
          _FeatureToggle(
            title: t.settings.title,
            icon: Icons.settings_outlined,
            value: state.config.settingsVisible,
            onChanged: (v) =>
                _updateFeature(ref, state.config.copyWith(settingsVisible: v)),
          ),
          const Divider(),
          _SectionHeader(title: t.childMode.mode),
          if (state.isPinSet)
            ListTile(
              leading: Icon(
                state.isChildMode ? Icons.child_care : Icons.supervisor_account,
                color: state.isChildMode ? Colors.orange : Colors.green,
              ),
              title: Text(
                state.isChildMode
                    ? t.childMode.childModeActive
                    : t.childMode.parentMode,
              ),
              trailing: FilledButton(
                onPressed: () {
                  if (state.isChildMode) {
                    _navigateToPinEntry(context);
                  } else {
                    ref.read(childModeProvider.notifier).enterChildMode();
                  }
                },
                child: Text(
                  state.isChildMode
                      ? t.childMode.exit
                      : t.childMode.enableChildMode,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToPinSetup(BuildContext context) {
    unawaited(
      Navigator.of(
        context,
      ).push(MaterialPageRoute<bool>(builder: (_) => const PinSetupScreen())),
    );
  }

  void _navigateToPinEntry(BuildContext context) {
    unawaited(
      Navigator.of(
        context,
      ).push(MaterialPageRoute<bool>(builder: (_) => const PinEntryScreen())),
    );
  }

  void _confirmRemovePin(BuildContext context, WidgetRef ref) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.childMode.removePinTitle),
          content: Text(t.childMode.removePinBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.common.cancel),
            ),
            FilledButton(
              onPressed: () {
                unawaited(ref.read(childModeProvider.notifier).removePin());
                Navigator.of(context).pop();
              },
              child: Text(t.common.delete),
            ),
          ],
        ),
      ),
    );
  }

  void _updateFeature(WidgetRef ref, ChildModeConfig config) {
    ref.read(childModeProvider.notifier).updateConfig(config);
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

class _FeatureToggle extends StatelessWidget {
  const _FeatureToggle({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}
