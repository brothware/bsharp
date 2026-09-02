import 'package:bsharp/data/data_sources/local/key_value_store_native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage secureStorage;
  late SecureKeyValueStore store;

  setUp(() {
    secureStorage = MockFlutterSecureStorage();
    store = SecureKeyValueStore(secureStorage);
    when(() => secureStorage.delete(key: any(named: 'key'))).thenAnswer(
      (_) async {},
    );
  });

  group('SecureKeyValueStore', () {
    test('returns the stored value', () async {
      when(
        () => secureStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'secret');

      expect(await store.read(key: 'token'), 'secret');
    });

    test('reads null for an absent key', () async {
      when(
        () => secureStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);

      expect(await store.read(key: 'token'), isNull);
    });

    test('treats an undecryptable entry as absent and discards it', () async {
      when(
        () => secureStorage.read(key: any(named: 'key')),
      ).thenThrow(PlatformException(code: 'Failed to decrypt'));

      expect(await store.read(key: 'token'), isNull);
      verify(() => secureStorage.delete(key: 'token')).called(1);
    });

    test('propagates failures that are not platform errors', () async {
      when(
        () => secureStorage.read(key: any(named: 'key')),
      ).thenThrow(StateError('boom'));

      await expectLater(
        store.read(key: 'token'),
        throwsA(isA<StateError>()),
      );
      verifyNever(() => secureStorage.delete(key: any(named: 'key')));
    });
  });
}
