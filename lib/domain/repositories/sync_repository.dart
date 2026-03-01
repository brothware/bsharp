import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/domain/entities/settings.dart';

enum SyncState { idle, syncing, completed, failed }

abstract interface class SyncRepository {
  Future<Result<void>> fullSync({required int studentId});

  Future<Result<void>> diffSync({required int studentId});

  Future<Result<ServerSettings>> getSettings();

  Stream<SyncState> watchSyncState();

  Future<DateTime?> getLastSyncTime();
}
