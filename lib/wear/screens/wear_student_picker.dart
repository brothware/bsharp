import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearStudentPicker extends ConsumerStatefulWidget {
  const WearStudentPicker({super.key});

  @override
  ConsumerState<WearStudentPicker> createState() => _WearStudentPickerState();
}

class _WearStudentPickerState extends ConsumerState<WearStudentPicker> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(allStudentsProvider);
    final activeSelection = ref.watch(activeSelectionProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      body: WearScaffold(
        scrollController: _scrollController,
        child: ListView(
          controller: _scrollController,
          children: [
            for (final entry in entries)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _selectStudent(ref, context, entry),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 18,
                          color: entry.student.id == activeSelection?.studentId
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${entry.student.name} ${entry.student.surname}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight:
                                  entry.student.id == activeSelection?.studentId
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ),
                        if (entry.student.id == activeSelection?.studentId)
                          Icon(
                            Icons.check,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _selectStudent(
    WidgetRef ref,
    BuildContext context,
    StudentEntry entry,
  ) {
    unawaited(
      ref
          .read(activeSelectionProvider.notifier)
          .select(
            ActiveSelection(
              accountId: entry.account.id,
              studentId: entry.student.id,
            ),
          ),
    );
    Navigator.of(context).pop();
  }
}
