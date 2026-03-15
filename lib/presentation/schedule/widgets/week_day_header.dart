import 'package:bsharp/domain/schedule_utils.dart';
import 'package:flutter/material.dart';

class WeekDayTab extends StatelessWidget {
  const WeekDayTab({required this.date, super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final isToday = isSameDay(date, DateTime.now());

    return Tab(
      height: 44,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayLabel(date.weekday),
            style: TextStyle(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.bold : null,
            ),
          ),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isToday ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}
