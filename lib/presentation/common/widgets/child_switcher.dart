import 'dart:async';

import 'package:bsharp/app/child_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChildSwitcher extends ConsumerWidget {
  const ChildSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentsProvider);
    final active = ref.watch(activeStudentProvider);

    if (active == null || active.name.isEmpty) {
      return const Text('BSharp');
    }

    return PopupMenuButton<int>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (id) {
        final student = students.firstWhere((s) => s.id == id);
        unawaited(ref.read(activeStudentProvider.notifier).switchTo(student));
      },
      itemBuilder: (context) => [
        for (final student in students)
          PopupMenuItem(
            value: student.id,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text(
                    student.name.isNotEmpty ? student.name[0] : '?',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${student.name} ${student.surname}'),
                if (student.id == active.id) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            child: Text(active.name[0], style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Text(
            '${active.name} ${active.surname}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (students.length > 1) const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}
