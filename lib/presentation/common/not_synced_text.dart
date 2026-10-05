import 'package:bsharp/app/sync_health_provider.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/relative_time.dart';

String notSyncedText(SyncHealth health, DataProviderCapability area) {
  final lastSyncedAt = health.lastSyncedAt[area];
  if (lastSyncedAt == null) {
    return t.common.notSynced;
  }
  return t.common.notSyncedSince(time: formatRelativeTime(lastSyncedAt));
}
