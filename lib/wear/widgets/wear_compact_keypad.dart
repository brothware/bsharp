import 'package:flutter/material.dart';

class WearCompactKeypad extends StatelessWidget {
  const WearCompactKeypad({required this.onKeyTap, super.key});

  final ValueChanged<String> onKeyTap;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', 'del'],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final row in _rows)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final key in row)
                if (key.isEmpty)
                  const SizedBox(width: 40, height: 36)
                else
                  InkWell(
                    onTap: () => onKeyTap(key),
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 40,
                      height: 36,
                      child: Center(
                        child: key == 'del'
                            ? Icon(
                                Icons.backspace_outlined,
                                size: 16,
                                color: theme.colorScheme.onSurface,
                              )
                            : Text(key, style: theme.textTheme.titleMedium),
                      ),
                    ),
                  ),
            ],
          ),
      ],
    );
  }
}
