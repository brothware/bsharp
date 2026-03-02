import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';

import '../data/credential_storage_test.dart';

ProviderContainer _createContainer({CredentialStorage? storage}) {
  final store = storage ?? CredentialStorage(store: FakeKeyValueStore());
  return ProviderContainer(
    overrides: [
      credentialStorageProvider.overrideWithValue(store),
    ],
  );
}

void main() {
  group('ChildModeConfig', () {
    test('defaults have correct visibility', () {
      const config = ChildModeConfig();
      expect(config.gradesVisible, isTrue);
      expect(config.scheduleVisible, isTrue);
      expect(config.attendanceVisible, isTrue);
      expect(config.messagesVisible, isFalse);
      expect(config.settingsVisible, isFalse);
      expect(config.notesVisible, isTrue);
    });

    test('isFeatureVisible maps all features', () {
      const config = ChildModeConfig();
      expect(config.isFeatureVisible(ChildModeFeature.grades), isTrue);
      expect(config.isFeatureVisible(ChildModeFeature.schedule), isTrue);
      expect(config.isFeatureVisible(ChildModeFeature.attendance), isTrue);
      expect(config.isFeatureVisible(ChildModeFeature.messages), isFalse);
      expect(config.isFeatureVisible(ChildModeFeature.settings), isFalse);
      expect(config.isFeatureVisible(ChildModeFeature.notes), isTrue);
    });

    test('copyWith overrides selected fields', () {
      const config = ChildModeConfig();
      final updated = config.copyWith(
        messagesVisible: true,
        gradesVisible: false,
      );
      expect(updated.messagesVisible, isTrue);
      expect(updated.gradesVisible, isFalse);
      expect(updated.scheduleVisible, isTrue);
    });
  });

  group('ChildModeState', () {
    test('defaults to parent mode', () {
      const state = ChildModeState();
      expect(state.isChildMode, isFalse);
      expect(state.isParentMode, isTrue);
      expect(state.isPinSet, isFalse);
      expect(state.failedAttempts, 0);
      expect(state.isLocked, isFalse);
    });

    test('isLocked returns true when lockedUntil is in the future', () {
      final state = ChildModeState(
        lockedUntil: DateTime.now().add(const Duration(minutes: 5)),
      );
      expect(state.isLocked, isTrue);
    });

    test('isLocked returns false when lockedUntil is in the past', () {
      final state = ChildModeState(
        lockedUntil: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(state.isLocked, isFalse);
    });

    test('clearLock resets lockedUntil', () {
      final state = ChildModeState(
        lockedUntil: DateTime.now().add(const Duration(minutes: 5)),
      );
      final cleared = state.copyWith(clearLock: true);
      expect(cleared.lockedUntil, isNull);
      expect(cleared.isLocked, isFalse);
    });
  });

  group('ChildModeNotifier', () {
    test('setupPin saves valid 4-digit PIN', () async {
      final container = _createContainer();
      final notifier = container.read(childModeProvider.notifier);

      final success = await notifier.setupPin('1234');
      expect(success, isTrue);
      expect(container.read(childModeProvider).isPinSet, isTrue);
    });

    test('setupPin saves valid 6-digit PIN', () async {
      final container = _createContainer();
      final notifier = container.read(childModeProvider.notifier);

      final success = await notifier.setupPin('123456');
      expect(success, isTrue);
      expect(container.read(childModeProvider).isPinSet, isTrue);
    });

    test('setupPin rejects too short PIN', () async {
      final container = _createContainer();
      final notifier = container.read(childModeProvider.notifier);

      final success = await notifier.setupPin('12');
      expect(success, isFalse);
    });

    test('setupPin rejects too long PIN', () async {
      final container = _createContainer();
      final notifier = container.read(childModeProvider.notifier);

      final success = await notifier.setupPin('1234567');
      expect(success, isFalse);
    });

    test('removePin clears state and exits child mode', () async {
      final container = _createContainer();
      final notifier = container.read(childModeProvider.notifier);

      await notifier.setupPin('1234');
      notifier.enterChildMode();
      expect(container.read(childModeProvider).isChildMode, isTrue);

      await notifier.removePin();
      final state = container.read(childModeProvider);
      expect(state.isPinSet, isFalse);
      expect(state.isChildMode, isFalse);
      expect(state.failedAttempts, 0);
    });

    test('verifyPin returns true for correct PIN', () async {
      final container = _createContainer();
      final notifier = container.read(childModeProvider.notifier);

      await notifier.setupPin('1234');
      expect(notifier.verifyPin('1234'), isTrue);
    });

    test('verifyPin returns false for wrong PIN', () async {
      final container = _createContainer();
      final notifier = container.read(childModeProvider.notifier);

      await notifier.setupPin('1234');
      expect(notifier.verifyPin('0000'), isFalse);
      expect(container.read(childModeProvider).failedAttempts, 1);
    });

    test('verifyPin locks after max attempts', () async {
      final container = _createContainer();
      final notifier = container.read(childModeProvider.notifier);

      await notifier.setupPin('1234');
      for (var i = 0; i < ChildModeNotifier.maxAttempts; i++) {
        notifier.verifyPin('0000');
      }

      final state = container.read(childModeProvider);
      expect(state.failedAttempts, ChildModeNotifier.maxAttempts);
      expect(state.isLocked, isTrue);
    });

    test('verifyPin fails when locked even with correct PIN', () async {
      final container = _createContainer();
      final notifier = container.read(childModeProvider.notifier);

      await notifier.setupPin('1234');
      for (var i = 0; i < ChildModeNotifier.maxAttempts; i++) {
        notifier.verifyPin('0000');
      }

      expect(notifier.verifyPin('1234'), isFalse);
    });

    test('successful verify resets failed attempts', () async {
      final container = _createContainer();
      final notifier = container.read(childModeProvider.notifier);

      await notifier.setupPin('1234');
      notifier.verifyPin('0000');
      notifier.verifyPin('0000');
      expect(container.read(childModeProvider).failedAttempts, 2);

      notifier.verifyPin('1234');
      expect(container.read(childModeProvider).failedAttempts, 0);
    });

    test('enterChildMode requires PIN to be set', () async {
      final container = _createContainer();
      final notifier = container.read(childModeProvider.notifier);

      notifier.enterChildMode();
      expect(container.read(childModeProvider).isChildMode, isFalse);

      await notifier.setupPin('1234');
      notifier.enterChildMode();
      expect(container.read(childModeProvider).isChildMode, isTrue);
    });

    test('exitChildMode requires correct PIN', () async {
      final container = _createContainer();
      final notifier = container.read(childModeProvider.notifier);

      await notifier.setupPin('1234');
      notifier.enterChildMode();

      expect(notifier.exitChildMode('0000'), isFalse);
      expect(container.read(childModeProvider).isChildMode, isTrue);

      expect(notifier.exitChildMode('1234'), isTrue);
      expect(container.read(childModeProvider).isChildMode, isFalse);
    });

    test('updateConfig changes feature visibility', () {
      final container = _createContainer();
      final notifier = container.read(childModeProvider.notifier);

      notifier.updateConfig(
        const ChildModeConfig(messagesVisible: true, gradesVisible: false),
      );

      final config = container.read(childModeProvider).config;
      expect(config.messagesVisible, isTrue);
      expect(config.gradesVisible, isFalse);
    });

    test('isFeatureVisible returns true in parent mode regardless of config',
        () async {
      final container = _createContainer();
      final notifier = container.read(childModeProvider.notifier);

      notifier.updateConfig(
        const ChildModeConfig(messagesVisible: false),
      );

      expect(notifier.isFeatureVisible(ChildModeFeature.messages), isTrue);
    });

    test('isFeatureVisible respects config in child mode', () async {
      final container = _createContainer();
      final notifier = container.read(childModeProvider.notifier);

      await notifier.setupPin('1234');
      notifier.updateConfig(
        const ChildModeConfig(messagesVisible: false, gradesVisible: true),
      );
      notifier.enterChildMode();

      expect(notifier.isFeatureVisible(ChildModeFeature.messages), isFalse);
      expect(notifier.isFeatureVisible(ChildModeFeature.grades), isTrue);
    });

    test('loadPin restores isPinSet from storage', () async {
      final fakeStorage = FakeKeyValueStore();
      await fakeStorage.write(key: 'child_mode_pin', value: '9999');
      final storage = CredentialStorage(store: fakeStorage);
      final container = _createContainer(storage: storage);

      container.read(childModeProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(childModeProvider).isPinSet, isTrue);
    });

    test('enterChildMode persists active state', () async {
      final fakeStorage = FakeKeyValueStore();
      final storage = CredentialStorage(store: fakeStorage);
      final container = _createContainer(storage: storage);
      final notifier = container.read(childModeProvider.notifier);

      await notifier.setupPin('1234');
      notifier.enterChildMode();

      expect(await storage.isChildModeActive(), isTrue);
    });

    test('exitChildMode persists inactive state', () async {
      final fakeStorage = FakeKeyValueStore();
      final storage = CredentialStorage(store: fakeStorage);
      final container = _createContainer(storage: storage);
      final notifier = container.read(childModeProvider.notifier);

      await notifier.setupPin('1234');
      notifier.enterChildMode();
      notifier.exitChildMode('1234');

      expect(await storage.isChildModeActive(), isFalse);
    });

    test('updateConfig persists config to storage', () async {
      final fakeStorage = FakeKeyValueStore();
      final storage = CredentialStorage(store: fakeStorage);
      final container = _createContainer(storage: storage);
      final notifier = container.read(childModeProvider.notifier);

      notifier.updateConfig(
        const ChildModeConfig(messagesVisible: true, gradesVisible: false),
      );

      final json = await storage.getChildModeConfig();
      expect(json, isNotNull);
      final decoded = jsonDecode(json!) as Map<String, dynamic>;
      expect(decoded['messagesVisible'], isTrue);
      expect(decoded['gradesVisible'], isFalse);
    });

    test('restores child mode and config from storage', () async {
      final fakeStorage = FakeKeyValueStore();
      await fakeStorage.write(key: 'child_mode_pin', value: '1234');
      await fakeStorage.write(key: 'child_mode_active', value: 'true');
      await fakeStorage.write(
        key: 'child_mode_config',
        value: jsonEncode({
          'gradesVisible': false,
          'scheduleVisible': true,
          'attendanceVisible': true,
          'messagesVisible': true,
          'settingsVisible': false,
          'notesVisible': true,
        }),
      );
      final storage = CredentialStorage(store: fakeStorage);
      final container = _createContainer(storage: storage);

      container.read(childModeProvider);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(childModeProvider);
      expect(state.isChildMode, isTrue);
      expect(state.config.gradesVisible, isFalse);
      expect(state.config.messagesVisible, isTrue);
    });

    test('restores failed attempts and lockout from storage', () async {
      final lockedUntil = DateTime.now().add(const Duration(minutes: 3));
      final fakeStorage = FakeKeyValueStore();
      await fakeStorage.write(key: 'child_mode_pin', value: '1234');
      await fakeStorage.write(
        key: 'child_mode_failed_attempts',
        value: '4',
      );
      await fakeStorage.write(
        key: 'child_mode_locked_until',
        value: lockedUntil.toIso8601String(),
      );
      final storage = CredentialStorage(store: fakeStorage);
      final container = _createContainer(storage: storage);

      container.read(childModeProvider);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(childModeProvider);
      expect(state.failedAttempts, 4);
      expect(state.isLocked, isTrue);
    });

    test('verifyPin persists lock state', () async {
      final fakeStorage = FakeKeyValueStore();
      final storage = CredentialStorage(store: fakeStorage);
      final container = _createContainer(storage: storage);
      final notifier = container.read(childModeProvider.notifier);

      await notifier.setupPin('1234');
      notifier.verifyPin('0000');

      expect(await storage.getChildModeFailedAttempts(), 1);
    });

    test('removePin clears all persisted state', () async {
      final fakeStorage = FakeKeyValueStore();
      final storage = CredentialStorage(store: fakeStorage);
      final container = _createContainer(storage: storage);
      final notifier = container.read(childModeProvider.notifier);

      await notifier.setupPin('1234');
      notifier.updateConfig(
        const ChildModeConfig(messagesVisible: true),
      );
      notifier.enterChildMode();
      await notifier.removePin();

      expect(await storage.getChildModePin(), isNull);
      expect(await storage.isChildModeActive(), isFalse);
      expect(await storage.getChildModeConfig(), isNull);
      expect(await storage.getChildModeFailedAttempts(), 0);
      expect(await storage.getChildModeLockedUntil(), isNull);
    });
  });

  group('ChildModeConfig serialization', () {
    test('toJson produces correct map', () {
      const config = ChildModeConfig();
      final json = config.toJson();
      expect(json['gradesVisible'], isTrue);
      expect(json['messagesVisible'], isFalse);
      expect(json['settingsVisible'], isFalse);
    });

    test('fromJson restores config', () {
      final config = ChildModeConfig.fromJson({
        'gradesVisible': false,
        'messagesVisible': true,
      });
      expect(config.gradesVisible, isFalse);
      expect(config.messagesVisible, isTrue);
      expect(config.scheduleVisible, isTrue);
    });

    test('fromJson uses defaults for missing keys', () {
      final config = ChildModeConfig.fromJson({});
      expect(config.gradesVisible, isTrue);
      expect(config.messagesVisible, isFalse);
    });
  });
}
