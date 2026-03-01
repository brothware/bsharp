import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';

class TermSelector extends ConsumerWidget {
  const TermSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terms = ref.watch(termsProvider);
    final currentTerm = ref.watch(currentTermProvider);

    if (terms.isEmpty) return const SizedBox.shrink();

    return DropdownButton<int>(
      value: currentTerm?.id,
      isExpanded: true,
      underline: const SizedBox.shrink(),
      icon: const Icon(Icons.arrow_drop_down),
      items: [
        for (final term in terms)
          DropdownMenuItem(
            value: term.id,
            child: Text(
              translateTermName(term.name),
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ],
      onChanged: (id) {
        if (id != null) {
          ref.read(selectedTermIdProvider.notifier).state = id;
        }
      },
    );
  }
}
