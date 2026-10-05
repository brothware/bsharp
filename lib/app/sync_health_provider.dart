import 'package:bsharp/domain/school_data_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class SyncHealth {
  const SyncHealth({
    this.staleAreas = const {},
    this.lastSyncedAt = const {},
  });

  final Set<DataProviderCapability> staleAreas;
  final Map<DataProviderCapability, DateTime> lastSyncedAt;

  bool isStale(DataProviderCapability area) => staleAreas.contains(area);

  SyncHealth markStale(Set<DataProviderCapability> areas) {
    return SyncHealth(
      staleAreas: {...staleAreas, ...areas},
      lastSyncedAt: lastSyncedAt,
    );
  }

  SyncHealth markSynced(Set<DataProviderCapability> areas, DateTime at) {
    return SyncHealth(
      staleAreas: staleAreas.difference(areas),
      lastSyncedAt: {
        ...lastSyncedAt,
        for (final area in areas) area: at,
      },
    );
  }
}

final syncHealthProvider = NotifierProvider<SyncHealthNotifier, SyncHealth>(
  SyncHealthNotifier.new,
);

class SyncHealthNotifier extends Notifier<SyncHealth> {
  @override
  SyncHealth build() => const SyncHealth();

  void markStale(Set<DataProviderCapability> areas) {
    state = state.markStale(areas);
  }

  void markSynced(Set<DataProviderCapability> areas, DateTime at) {
    state = state.markSynced(areas, at);
  }
}
