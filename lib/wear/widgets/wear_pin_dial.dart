import 'dart:math' as math;

import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/wear_app.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';

const _keyDiameter = 48.0;
const _keyFaceDiameter = 40.0;
const _dotDiameter = 12.0;
const _dotSpacing = 8.0;
const _dialDigits = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];

List<Offset> wearDialKeyCentres({
  required Size size,
  required WearScreenShape shape,
}) => switch (shape) {
  WearScreenShape.round => _ringCentres(size),
  WearScreenShape.rectangular => _frameCentres(size),
};

List<Offset> _ringCentres(Size size) {
  const keyRadius = _keyDiameter / 2;
  final step = 2 * math.pi / _dialDigits.length;
  final touchingRadius = keyRadius / math.sin(step / 2);
  final huggingRadius = size.shortestSide / 2 - keyRadius;
  final radius = math.max(touchingRadius, huggingRadius);
  final centre = size.center(Offset.zero);
  return [
    for (var index = 0; index < _dialDigits.length; index++)
      centre +
          Offset(
            radius * math.sin((index + 0.5) * step),
            -radius * math.cos((index + 0.5) * step),
          ),
  ];
}

List<Offset> _frameCentres(Size size) {
  const half = _keyDiameter / 2;
  const left = half;
  final right = size.width - half;
  const top = half;
  final bottom = size.height - half;
  final middleX = size.width / 2;
  final thirdY = top + (bottom - top) / 3;
  final twoThirdsY = top + (bottom - top) * 2 / 3;
  return [
    const Offset(left, top),
    Offset(middleX, top),
    Offset(right, top),
    Offset(right, thirdY),
    Offset(right, twoThirdsY),
    Offset(right, bottom),
    Offset(middleX, bottom),
    Offset(left, bottom),
    Offset(left, twoThirdsY),
    Offset(left, thirdY),
  ];
}

Rect _centreArea(Size size, WearScreenShape shape) {
  final bounds = Offset.zero & size;
  switch (shape) {
    case WearScreenShape.round:
      final centres = _ringCentres(size);
      final innerRadius =
          (centres.first - bounds.center).distance - _keyFaceDiameter / 2;
      return Rect.fromCircle(
        center: bounds.center,
        radius: innerRadius / math.sqrt2,
      );
    case WearScreenShape.rectangular:
      return bounds.deflate(_keyDiameter);
  }
}

class WearPinDial extends StatelessWidget {
  const WearPinDial({
    required this.shape,
    required this.prompt,
    required this.enteredCount,
    required this.pinLength,
    required this.onKeyTap,
    this.error,
    super.key,
  });

  static const deleteKey = 'del';

  final WearScreenShape shape;
  final String prompt;
  final String? error;
  final int enteredCount;
  final int pinLength;
  final ValueChanged<String> onKeyTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final centres = wearDialKeyCentres(size: size, shape: shape);
        final centreArea = _centreArea(size, shape);
        return Stack(
          children: [
            Positioned(
              left: centreArea.left,
              width: centreArea.width,
              top: 0,
              bottom: 0,
              child: Center(
                child: enteredCount == 0
                    ? _PinMessage(prompt: prompt, error: error)
                    : _PinProgress(
                        enteredCount: enteredCount,
                        pinLength: pinLength,
                        onDelete: () => onKeyTap(deleteKey),
                      ),
              ),
            ),
            for (var index = 0; index < _dialDigits.length; index++)
              Positioned.fromRect(
                rect: Rect.fromCircle(
                  center: centres[index],
                  radius: _keyDiameter / 2,
                ),
                child: _DialKey(
                  digit: _dialDigits[index],
                  onTap: () => onKeyTap(_dialDigits[index]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PinMessage extends StatelessWidget {
  const _PinMessage({required this.prompt, required this.error});

  final String prompt;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = error;
    return Semantics(
      liveRegion: message != null,
      child: Text(
        message ?? prompt,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: message == null ? null : theme.colorScheme.error,
        ),
      ),
    );
  }
}

class _PinProgress extends StatelessWidget {
  const _PinProgress({
    required this.enteredCount,
    required this.pinLength,
    required this.onDelete,
  });

  final int enteredCount;
  final int pinLength;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < pinLength; index++)
              WearPinDot(isFilled: index < enteredCount),
          ],
        ),
        IconButton(
          tooltip: t.common.delete,
          onPressed: onDelete,
          style: IconButton.styleFrom(
            minimumSize: const Size.square(_keyDiameter),
          ),
          icon: const Icon(Icons.backspace_outlined),
        ),
      ],
    );
  }
}

class WearPinDot extends StatelessWidget {
  const WearPinDot({required this.isFilled, super.key});

  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _dotSpacing / 2),
      width: _dotDiameter,
      height: _dotDiameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled ? scheme.primary : wearTrackColor(scheme),
      ),
    );
  }
}

class _DialKey extends StatelessWidget {
  const _DialKey({required this.digit, required this.onTap});

  final String digit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Center(
        child: Container(
          width: _keyFaceDiameter,
          height: _keyFaceDiameter,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: wearTrackColor(theme.colorScheme),
          ),
          child: Text(digit, style: theme.textTheme.titleMedium),
        ),
      ),
    );
  }
}
