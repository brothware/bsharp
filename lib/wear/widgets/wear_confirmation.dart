import 'dart:math' as math;

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

/// The pill is drawn 40dp tall so it stops dominating a 177dp screen, while
/// MaterialTapTargetSize.padded keeps the target the 48dp Wear asks for.
const double _buttonHeight = 40;

/// How wide the buttons may be without their bottom corners leaving the glass.
///
/// They sit at the foot of the screen, where a round display has given up most
/// of its width, so the full content width runs the corners past the bezel.
double _buttonWidth(BuildContext context) {
  final display = WearDisplayScope.of(context);
  final content = display.sizeDp.shortestSide * (1 - 2 * kWearRoundInsetFactor);
  if (!display.isRound) return content;

  final radius = display.sizeDp.shortestSide / 2;
  final fromCentre = radius - radius * 2 * kWearRoundInsetFactor;
  final halfWidth = math.sqrt(
    math.max(0, radius * radius - fromCentre * fromCentre),
  );

  return math.min(content, halfWidth * 2);
}

class _WearConfirmationScreen extends StatefulWidget {
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
  State<_WearConfirmationScreen> createState() =>
      _WearConfirmationScreenState();
}

class _WearConfirmationScreenState extends State<_WearConfirmationScreen> {
  final _questionScrollController = ScrollController();

  @override
  void dispose() {
    _questionScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _WearConfirmationScreen(
      :icon,
      :question,
      :confirmLabel,
      :cancelLabel,
      :isDestructive,
    ) = widget;
    final accentColor = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Scaffold(
      body: WearSwipeDismiss(
        child: WearScaffold(
          scrollController: _questionScrollController,
          child: Builder(
            builder: (context) => Column(
              children: [
                Icon(icon, size: 16, color: accentColor),
                const SizedBox(height: 2),
                Expanded(
                  // Two 48dp buttons and an icon leave the question very little
                  // of a round watch. Scaling it to fit took it as low as 5sp
                  // on a 192dp watch (WO-V14), so a long one scrolls instead,
                  // with the edge scrollbar showing there is more (WO-V8).
                  child: SingleChildScrollView(
                    controller: _questionScrollController,
                    child: Text(
                      question,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Center(
                  child: SizedBox(
                    width: _buttonWidth(context),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(_buttonHeight),
                        tapTargetSize: MaterialTapTargetSize.padded,
                        textStyle: theme.textTheme.labelMedium,
                        backgroundColor: isDestructive ? accentColor : null,
                        foregroundColor: isDestructive
                            ? theme.colorScheme.onError
                            : null,
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(confirmLabel),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Center(
                  child: SizedBox(
                    width: _buttonWidth(context),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(_buttonHeight),
                        tapTargetSize: MaterialTapTargetSize.padded,
                        textStyle: theme.textTheme.labelMedium,
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(cancelLabel ?? t.common.cancel),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
