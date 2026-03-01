import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/screens/wear_pin_entry.dart';
import 'package:bsharp/wear/screens/wear_pin_setup_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_screen_layout.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';

class WearChildModeScreen extends ConsumerWidget {
  const WearChildModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shape = ref.watch(wearScreenShapeProvider).requireValue;
    final state = ref.watch(childModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: WearSwipeDismiss(
        child: WearScreenLayout(
          child: Column(
            children: [
              Icon(
                Icons.child_care,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 2),
              Text(
                t.childMode.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(bottom: wearListBottomInset(shape)),
                  children: [
                    _WearSectionLabel(label: t.childMode.pin),
                    if (!state.isPinSet)
                      _WearChildModeItem(
                        icon: Icons.add,
                        label: t.childMode.setPin,
                        onTap: () => _navigateToPinSetup(context),
                      )
                    else ...[
                      _WearChildModeItem(
                        icon: Icons.check_circle,
                        label: t.childMode.pinSet,
                        iconColor: Colors.green,
                      ),
                      _WearChildModeItem(
                        icon: Icons.edit,
                        label: t.childMode.changePin,
                        onTap: () => _navigateToPinSetup(context),
                      ),
                      _WearChildModeItem(
                        icon: Icons.delete,
                        label: t.childMode.removePin,
                        iconColor: theme.colorScheme.error,
                        onTap: () => _showRemovePinDialog(context, ref),
                      ),
                    ],
                    if (state.isPinSet) ...[
                      _WearSectionLabel(label: t.childMode.visibleFeatures),
                      _WearFeatureToggle(
                        label: t.nav.schedule,
                        value: state.config.scheduleVisible,
                        onChanged: (v) => ref
                            .read(childModeProvider.notifier)
                            .updateConfig(
                              state.config.copyWith(scheduleVisible: v),
                            ),
                      ),
                      _WearFeatureToggle(
                        label: t.nav.grades,
                        value: state.config.gradesVisible,
                        onChanged: (v) => ref
                            .read(childModeProvider.notifier)
                            .updateConfig(
                              state.config.copyWith(gradesVisible: v),
                            ),
                      ),
                      _WearFeatureToggle(
                        label: t.nav.attendance,
                        value: state.config.attendanceVisible,
                        onChanged: (v) => ref
                            .read(childModeProvider.notifier)
                            .updateConfig(
                              state.config.copyWith(attendanceVisible: v),
                            ),
                      ),
                      _WearFeatureToggle(
                        label: t.nav.messages,
                        value: state.config.messagesVisible,
                        onChanged: (v) => ref
                            .read(childModeProvider.notifier)
                            .updateConfig(
                              state.config.copyWith(messagesVisible: v),
                            ),
                      ),
                      _WearFeatureToggle(
                        label: t.nav.notes,
                        value: state.config.notesVisible,
                        onChanged: (v) => ref
                            .read(childModeProvider.notifier)
                            .updateConfig(
                              state.config.copyWith(notesVisible: v),
                            ),
                      ),
                      _WearFeatureToggle(
                        label: t.settings.title,
                        value: state.config.settingsVisible,
                        onChanged: (v) => ref
                            .read(childModeProvider.notifier)
                            .updateConfig(
                              state.config.copyWith(settingsVisible: v),
                            ),
                      ),
                      const SizedBox(height: 4),
                      _WearSectionLabel(label: t.childMode.mode),
                      if (state.isParentMode)
                        _WearChildModeItem(
                          icon: Icons.child_care,
                          label: t.childMode.enableChildMode,
                          onTap: () {
                            ref
                                .read(childModeProvider.notifier)
                                .enterChildMode();
                            Navigator.of(context).pop();
                          },
                        )
                      else
                        _WearChildModeItem(
                          icon: Icons.child_care,
                          label: t.childMode.childModeActive,
                          iconColor: Colors.orange,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const WearPinEntry(),
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPinSetup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => const WearPinSetupScreen(),
      ),
    );
  }

  void _showRemovePinDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.childMode.removePinTitle),
        content: Text(t.childMode.removePinBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(childModeProvider.notifier).removePin();
            },
            child: Text(t.childMode.removePin),
          ),
        ],
      ),
    );
  }
}

class _WearSectionLabel extends StatelessWidget {
  const _WearSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 10,
            ),
      ),
    );
  }
}

class _WearChildModeItem extends StatelessWidget {
  const _WearChildModeItem({
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
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: iconColor ?? theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WearFeatureToggle extends StatelessWidget {
  const _WearFeatureToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ),
          SizedBox(
            height: 24,
            child: FittedBox(
              child: Switch(
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
