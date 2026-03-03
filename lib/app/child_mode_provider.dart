import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/auth_provider.dart';

enum AppMode { parent, child }

class ChildModeConfig {
  const ChildModeConfig({
    this.gradesVisible = true,
    this.scheduleVisible = true,
    this.attendanceVisible = true,
    this.messagesVisible = false,
    this.settingsVisible = false,
    this.notesVisible = true,
  });

  factory ChildModeConfig.fromJson(Map<String, dynamic> json) {
    return ChildModeConfig(
      gradesVisible: json['gradesVisible'] as bool? ?? true,
      scheduleVisible: json['scheduleVisible'] as bool? ?? true,
      attendanceVisible: json['attendanceVisible'] as bool? ?? true,
      messagesVisible: json['messagesVisible'] as bool? ?? false,
      settingsVisible: json['settingsVisible'] as bool? ?? false,
      notesVisible: json['notesVisible'] as bool? ?? true,
    );
  }

  final bool gradesVisible;
  final bool scheduleVisible;
  final bool attendanceVisible;
  final bool messagesVisible;
  final bool settingsVisible;
  final bool notesVisible;

  ChildModeConfig copyWith({
    bool? gradesVisible,
    bool? scheduleVisible,
    bool? attendanceVisible,
    bool? messagesVisible,
    bool? settingsVisible,
    bool? notesVisible,
  }) {
    return ChildModeConfig(
      gradesVisible: gradesVisible ?? this.gradesVisible,
      scheduleVisible: scheduleVisible ?? this.scheduleVisible,
      attendanceVisible: attendanceVisible ?? this.attendanceVisible,
      messagesVisible: messagesVisible ?? this.messagesVisible,
      settingsVisible: settingsVisible ?? this.settingsVisible,
      notesVisible: notesVisible ?? this.notesVisible,
    );
  }

  bool isFeatureVisible(ChildModeFeature feature) {
    return switch (feature) {
      ChildModeFeature.grades => gradesVisible,
      ChildModeFeature.schedule => scheduleVisible,
      ChildModeFeature.attendance => attendanceVisible,
      ChildModeFeature.messages => messagesVisible,
      ChildModeFeature.settings => settingsVisible,
      ChildModeFeature.notes => notesVisible,
    };
  }

  Map<String, dynamic> toJson() => {
    'gradesVisible': gradesVisible,
    'scheduleVisible': scheduleVisible,
    'attendanceVisible': attendanceVisible,
    'messagesVisible': messagesVisible,
    'settingsVisible': settingsVisible,
    'notesVisible': notesVisible,
  };
}

enum ChildModeFeature {
  grades,
  schedule,
  attendance,
  messages,
  settings,
  notes,
}

class ChildModeState {
  const ChildModeState({
    this.mode = AppMode.parent,
    this.config = const ChildModeConfig(),
    this.isPinSet = false,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  final AppMode mode;
  final ChildModeConfig config;
  final bool isPinSet;
  final int failedAttempts;
  final DateTime? lockedUntil;

  bool get isChildMode => mode == AppMode.child;
  bool get isParentMode => mode == AppMode.parent;

  bool get isLocked {
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil!);
  }

  ChildModeState copyWith({
    AppMode? mode,
    ChildModeConfig? config,
    bool? isPinSet,
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearLock = false,
  }) {
    return ChildModeState(
      mode: mode ?? this.mode,
      config: config ?? this.config,
      isPinSet: isPinSet ?? this.isPinSet,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: clearLock ? null : (lockedUntil ?? this.lockedUntil),
    );
  }
}

final childModeProvider = NotifierProvider<ChildModeNotifier, ChildModeState>(
  ChildModeNotifier.new,
);

class ChildModeNotifier extends Notifier<ChildModeState> {
  static const maxAttempts = 5;
  static const lockoutDuration = Duration(minutes: 5);
  String? _storedPin;

  @override
  ChildModeState build() {
    _loadState();
    return const ChildModeState();
  }

  Future<void> _loadState() async {
    final storage = ref.read(credentialStorageProvider);
    _storedPin = await storage.getChildModePin();

    final isActive = await storage.isChildModeActive();
    final configJson = await storage.getChildModeConfig();
    final failedAttempts = await storage.getChildModeFailedAttempts();
    final lockedUntil = await storage.getChildModeLockedUntil();

    var config = const ChildModeConfig();
    if (configJson != null) {
      final decoded = jsonDecode(configJson) as Map<String, dynamic>;
      config = ChildModeConfig.fromJson(decoded);
    }

    state = ChildModeState(
      mode: isActive && _storedPin != null ? AppMode.child : AppMode.parent,
      config: config,
      isPinSet: _storedPin != null,
      failedAttempts: failedAttempts,
      lockedUntil: lockedUntil,
    );
  }

  Future<bool> setupPin(String pin) {
    return changePin(pin);
  }

  Future<bool> changePin(String newPin) async {
    if (newPin.length < 4 || newPin.length > 6) return false;

    final storage = ref.read(credentialStorageProvider);
    await storage.saveChildModePin(newPin);
    _storedPin = newPin;
    state = state.copyWith(isPinSet: true);
    return true;
  }

  Future<void> removePin() async {
    final storage = ref.read(credentialStorageProvider);
    await Future.wait([
      storage.clearChildModePin(),
      storage.clearChildModeState(),
    ]);
    _storedPin = null;
    state = state.copyWith(
      isPinSet: false,
      mode: AppMode.parent,
      failedAttempts: 0,
      clearLock: true,
    );
  }

  bool verifyPin(String pin) {
    if (state.isLocked) return false;

    if (_storedPin == null) return false;

    if (pin == _storedPin) {
      state = state.copyWith(failedAttempts: 0, clearLock: true);
      _persistLockState();
      return true;
    }

    final attempts = state.failedAttempts + 1;
    if (attempts >= maxAttempts) {
      state = state.copyWith(
        failedAttempts: attempts,
        lockedUntil: DateTime.now().add(lockoutDuration),
      );
    } else {
      state = state.copyWith(failedAttempts: attempts);
    }
    _persistLockState();
    return false;
  }

  void enterChildMode() {
    if (!state.isPinSet) return;
    state = state.copyWith(mode: AppMode.child);
    _persistMode();
  }

  bool exitChildMode(String pin) {
    if (verifyPin(pin)) {
      state = state.copyWith(mode: AppMode.parent);
      _persistMode();
      return true;
    }
    return false;
  }

  void updateConfig(ChildModeConfig config) {
    state = state.copyWith(config: config);
    _persistConfig();
  }

  void _persistMode() {
    ref
        .read(credentialStorageProvider)
        .saveChildModeActive(active: state.isChildMode);
  }

  void _persistConfig() {
    ref
        .read(credentialStorageProvider)
        .saveChildModeConfig(jsonEncode(state.config.toJson()));
  }

  void _persistLockState() {
    ref.read(credentialStorageProvider)
      ..saveChildModeFailedAttempts(state.failedAttempts)
      ..saveChildModeLockedUntil(state.lockedUntil);
  }

  bool isFeatureVisible(ChildModeFeature feature) {
    if (state.isParentMode) return true;
    return state.config.isFeatureVisible(feature);
  }
}
