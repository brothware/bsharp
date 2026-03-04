import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinPad extends StatefulWidget {
  const PinPad({
    required this.onComplete,
    required this.title,
    super.key,
    this.pinLength = 4,
    this.errorMessage,
  });

  final void Function(String pin) onComplete;
  final int pinLength;
  final String title;
  final String? errorMessage;

  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadState extends State<PinPad> with SingleTickerProviderStateMixin {
  String _pin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void shake() {
    unawaited(_shakeController.forward(from: 0));
    setState(() => _pin = '');
  }

  void clear() {
    setState(() => _pin = '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final offset =
                _shakeAnimation.value *
                10 *
                ((_shakeController.value * 8).round().isOdd ? 1 : -1);
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.pinLength,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.errorMessage!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 32),
        _buildKeypad(theme),
      ],
    );
  }

  Widget _buildKeypad(ThemeData theme) {
    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'del'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final key in row)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: key.isEmpty
                        ? const SizedBox(width: 72, height: 72)
                        : _KeyButton(label: key, onTap: () => _onKeyTap(key)),
                  ),
              ],
            ),
          ),
      ],
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

    if (_pin.length >= widget.pinLength) return;

    setState(() => _pin += key);

    if (_pin.length == widget.pinLength) {
      widget.onComplete(_pin);
    }
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDel = label == 'del';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          child: isDel
              ? Icon(
                  Icons.backspace_outlined,
                  color: theme.colorScheme.onSurface,
                )
              : Text(label, style: theme.textTheme.headlineMedium),
        ),
      ),
    );
  }
}
