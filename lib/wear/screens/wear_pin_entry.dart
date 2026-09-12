import 'dart:async';

import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/widgets/wear_compact_keypad.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar.dart';

class WearPinEntry extends ConsumerStatefulWidget {
  const WearPinEntry({super.key});

  @override
  ConsumerState<WearPinEntry> createState() => _WearPinEntryState();
}

class _WearPinEntryState extends ConsumerState<WearPinEntry> {
  final _scrollController = ScrollController();
  String _pin = '';
  String? _error;
  static const _pinLength = 4;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(childModeProvider);
    final theme = Theme.of(context);

    if (state.isLocked) {
      return Scaffold(
        body: WearSwipeDismiss(
          child: WearScaffold(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_clock,
                    size: 36,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 8),
                  Text(t.childMode.locked, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    t.childMode.tryAgainLater,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: WearSwipeDismiss(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => WearOsScrollbar(
              controller: _scrollController,
              indicatorColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        t.childMode.enterParentPin,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pinLength, (i) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < _pin.length
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                            ),
                          );
                        }),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _error!,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      WearCompactKeypad(onKeyTap: _onKeyTap),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onKeyTap(String key) {
    unawaited(HapticFeedback.lightImpact());

    if (key == 'del') {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
      return;
    }

    if (_pin.length >= _pinLength) return;

    setState(() {
      _pin += key;
      _error = null;
    });

    if (_pin.length == _pinLength) {
      final success = ref.read(childModeProvider.notifier).exitChildMode(_pin);
      if (success) {
        Navigator.of(context).pop();
      } else {
        final remaining =
            ChildModeNotifier.maxAttempts -
            ref.read(childModeProvider).failedAttempts;
        setState(() {
          _error = remaining > 0
              ? t.childMode.attemptsRemaining(remaining: remaining.toString())
              : t.childMode.tooManyAttempts;
          _pin = '';
        });
      }
    }
  }
}
