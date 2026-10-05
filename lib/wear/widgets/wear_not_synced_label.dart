import 'package:bsharp/app/sync_health_provider.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/presentation/common/not_synced_text.dart';
import 'package:bsharp/wear/widgets/wear_fitted_text.dart';
import 'package:bsharp/wear/widgets/wear_pinned_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearNotSyncedLabel extends ConsumerWidget {
  const WearNotSyncedLabel({required this.area, super.key});

  final DataProviderCapability area;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(syncHealthProvider);
    if (!health.isStale(area)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return WearPinnedHeader(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sync_problem_outlined,
            size: 16,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: WearFittedText(
              notSyncedText(health, area),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
