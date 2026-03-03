import 'package:flutter/material.dart';
import 'package:bsharp/domain/schedule_utils.dart';

class WeekDayHeader extends StatelessWidget {
  const WeekDayHeader({
    super.key,
    required this.date,
    required this.isSelected,
    this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = isSameDay(date, DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : isToday
              ? theme.colorScheme.secondaryContainer
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dayLabel(date.weekday),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : isToday
                    ? theme.colorScheme.onSecondaryContainer
                    : null,
                fontWeight: isSelected || isToday ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
