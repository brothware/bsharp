import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/services/sync_engine.dart';
import 'package:bsharp/domain/entities/settings.dart';
import 'package:bsharp/domain/repositories/sync_repository.dart';

class _FakeSyncRepository implements SyncRepository {
  Result<void> fullSyncResult = const Result.success(null);
  Result<void> diffSyncResult = const Result.success(null);
  int fullSyncCount = 0;
  int diffSyncCount = 0;

  @override
  Future<Result<void>> fullSync({required int studentId}) async {
    fullSyncCount++;
    return fullSyncResult;
  }

  @override
  Future<Result<void>> diffSync({required int studentId}) async {
    diffSyncCount++;
    return diffSyncResult;
  }

  @override
  Future<Result<ServerSettings>> getSettings() async {
    return Result.success(
      ServerSettings(
        version: '1.0',
        protocol: '1.6.0',
        id: 'test',
        time: DateTime(2025, 1, 1),
        permissions: 0,
      ),
    );
  }

  @override
  Stream<SyncState> watchSyncState() => const Stream.empty();

  @override
  Future<DateTime?> getLastSyncTime() async => null;
}

void main() {
  late _FakeSyncRepository repository;
  late SyncEngine engine;

  setUp(() {
    repository = _FakeSyncRepository();
    engine = SyncEngine(repository: repository);
  });

  tearDown(() => engine.dispose());

  group('SyncEngine', () {
    test('initial state is idle', () {
      expect(engine.state.isIdle, isTrue);
      expect(engine.state.isSyncing, isFalse);
      expect(engine.state.lastSyncTime, isNull);
    });

    test('sync calls diffSync on repository', () async {
      await engine.sync(studentId: 1);
      expect(repository.diffSyncCount, 1);
    });

    test('sync updates state to completed on success', () async {
      await engine.sync(studentId: 1);
      expect(engine.state.status, SyncState.completed);
      expect(engine.state.lastSyncTime, isNotNull);
    });

    test('sync updates state to failed on failure', () async {
      repository.diffSyncResult = const Result.failure(
        NoConnection(message: 'offline'),
      );
      await engine.sync(studentId: 1);
      expect(engine.state.status, SyncState.failed);
      expect(engine.state.lastError, 'offline');
    });

    test('consecutive failures increment counter', () async {
      repository.diffSyncResult = const Result.failure(
        NoConnection(message: 'offline'),
      );
      await engine.sync(studentId: 1);
      await engine.sync(studentId: 1);
      expect(engine.consecutiveFailures, 2);
    });

    test('success resets failure counter', () async {
      repository.diffSyncResult = const Result.failure(
        NoConnection(message: 'offline'),
      );
      await engine.sync(studentId: 1);
      await engine.sync(studentId: 1);

      repository.diffSyncResult = const Result.success(null);
      await engine.sync(studentId: 1);
      expect(engine.consecutiveFailures, 0);
    });

    test('forceFullSync calls fullSync on repository', () async {
      await engine.forceFullSync(studentId: 1);
      expect(repository.fullSyncCount, 1);
    });

    test('nextSyncInterval increases with failures', () async {
      final baseInterval = engine.nextSyncInterval;

      repository.diffSyncResult = const Result.failure(
        NoConnection(message: 'offline'),
      );
      await engine.sync(studentId: 1);

      expect(engine.nextSyncInterval, greaterThan(baseInterval));
    });

    test('does not sync concurrently', () async {
      repository.diffSyncResult = const Result.success(null);

      final future1 = engine.sync(studentId: 1);
      final future2 = engine.sync(studentId: 1);
      await Future.wait([future1, future2]);

      expect(repository.diffSyncCount, 1);
    });

    test('state stream emits changes', () async {
      final states = <SyncEngineState>[];
      engine.stateStream.listen(states.add);

      await engine.sync(studentId: 1);
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0].isSyncing, isTrue);
      expect(states[1].status, SyncState.completed);
    });
  });
}
