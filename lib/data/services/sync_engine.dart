import 'dart:async';

import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/domain/repositories/sync_repository.dart';

class SyncEngine {
  SyncEngine({required SyncRepository repository}) : _repository = repository;

  final SyncRepository _repository;
  final _stateController = StreamController<SyncEngineState>.broadcast();
  SyncEngineState _state = const SyncEngineState();
  int _consecutiveFailures = 0;
  final _backoff = const BackoffStrategy();

  SyncEngineState get state => _state;
  Stream<SyncEngineState> get stateStream => _stateController.stream;

  Future<ChangeSet> sync({required int studentId}) async {
    if (_state.isSyncing) return const ChangeSet();

    _updateState(_state.copyWith(status: SyncState.syncing));

    final result = await _repository.diffSync(studentId: studentId);

    return result.when(
      success: (_) {
        _consecutiveFailures = 0;
        final now = DateTime.now();
        _updateState(
          _state.copyWith(
            status: SyncState.completed,
            lastSyncTime: now,
            lastError: null,
          ),
        );
        return const ChangeSet();
      },
      failure: (failure) {
        _consecutiveFailures++;
        _updateState(
          _state.copyWith(status: SyncState.failed, lastError: failure.message),
        );
        return const ChangeSet();
      },
    );
  }

  Future<Result<void>> forceFullSync({required int studentId}) async {
    if (_state.isSyncing)
      return const Result.failure(UnknownFailure(message: 'Sync in progress'));

    _updateState(_state.copyWith(status: SyncState.syncing));

    final result = await _repository.fullSync(studentId: studentId);

    return result.when(
      success: (_) {
        _consecutiveFailures = 0;
        final now = DateTime.now();
        _updateState(
          _state.copyWith(
            status: SyncState.completed,
            lastSyncTime: now,
            lastError: null,
          ),
        );
        return const Result.success(null);
      },
      failure: (failure) {
        _consecutiveFailures++;
        _updateState(
          _state.copyWith(status: SyncState.failed, lastError: failure.message),
        );
        return Result.failure(failure);
      },
    );
  }

  Duration get nextSyncInterval =>
      _backoff.intervalAfterFailures(_consecutiveFailures);

  int get consecutiveFailures => _consecutiveFailures;

  void resetFailures() {
    _consecutiveFailures = 0;
  }

  void _updateState(SyncEngineState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void dispose() {
    _stateController.close();
  }
}

class SyncEngineState {
  const SyncEngineState({
    this.status = SyncState.idle,
    this.lastSyncTime,
    this.lastError,
  });

  final SyncState status;
  final DateTime? lastSyncTime;
  final String? lastError;

  bool get isSyncing => status == SyncState.syncing;
  bool get isIdle => status == SyncState.idle;

  SyncEngineState copyWith({
    SyncState? status,
    DateTime? lastSyncTime,
    String? lastError,
  }) {
    return SyncEngineState(
      status: status ?? this.status,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError,
    );
  }
}
