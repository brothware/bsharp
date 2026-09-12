import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:flutter/material.dart';

Future<bool> showWearConfirmation(
  BuildContext context, {
  required IconData icon,
  required String question,
  required String confirmLabel,
  String? cancelLabel,
  bool isDestructive = false,
}) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => _WearConfirmationScreen(
        icon: icon,
        question: question,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    ),
  );
  return result ?? false;
}

class _WearConfirmationScreen extends StatelessWidget {
  const _WearConfirmationScreen({
    required this.icon,
    required this.question,
    required this.confirmLabel,
    required this.isDestructive,
    this.cancelLabel,
  });

  final IconData icon;
  final String question;
  final String confirmLabel;
  final String? cancelLabel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Scaffold(
      body: WearSwipeDismiss(
        child: WearScaffold(
          child: Column(
            children: [
              Icon(icon, size: 20, color: accentColor),
              const SizedBox(height: 4),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    question,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: isDestructive ? accentColor : null,
                    foregroundColor: isDestructive
                        ? theme.colorScheme.onError
                        : null,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirmLabel),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(cancelLabel ?? t.common.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
