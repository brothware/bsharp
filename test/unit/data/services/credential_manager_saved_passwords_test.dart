import 'package:bsharp/data/services/credential_manager_saved_passwords.dart';
import 'package:bsharp/domain/entities/saved_login.dart';
import 'package:bsharp/domain/saved_passwords.dart';
import 'package:credential_manager/credential_manager.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCredentialManager implements CredentialManager {
  _FakeCredentialManager({this.picked, this.error});

  final PasswordCredential? picked;
  final CredentialException? error;
  final saved = <PasswordCredential>[];
  int inits = 0;

  @override
  Future<void> init({
    required bool preferImmediatelyAvailableCredentials,
    String? googleClientId,
  }) async {
    inits++;
  }

  @override
  Future<void> savePasswordCredentials(PasswordCredential credential) async {
    if (error case final error?) {
      throw error;
    }
    saved.add(credential);
  }

  @override
  Future<Credentials> getCredentials({
    CredentialLoginOptions? passKeyOption,
    FetchOptionsAndroid? fetchOptions,
  }) async {
    if (error case final error?) {
      throw error;
    }
    return Credentials(passwordCredential: picked);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CredentialException _code(int code) =>
    CredentialException(code: code, message: 'code $code', details: null);

const _login = SavedLogin(
  school: 'osm-wroclaw',
  login: 'parent',
  password: 'secret',
);

void main() {
  group('saved username', () {
    test('keeps school and login together', () {
      expect(savedUsernameOf(_login), 'parent@osm-wroclaw');
      expect(
        savedLoginOf('parent@osm-wroclaw', 'secret'),
        _login,
      );
    });

    test('a login that holds an @ splits on the last one', () {
      expect(
        savedLoginOf('jan@kowalski@sp1', 'p'),
        const SavedLogin(school: 'sp1', login: 'jan@kowalski', password: 'p'),
      );
    });

    test('a username with no school is not a BSharp login', () {
      expect(savedLoginOf('parent', 'secret'), isNull);
      expect(savedLoginOf('parent@', 'secret'), isNull);
      expect(savedLoginOf('@sp1', 'secret'), isNull);
    });
  });

  group('CredentialManagerSavedPasswords', () {
    test('offering to save stores school and login once initialised', () async {
      final manager = _FakeCredentialManager();
      final passwords = CredentialManagerSavedPasswords(manager);

      await passwords.offerToSave(_login);
      await passwords.offerToSave(_login);

      expect(manager.inits, 1);
      expect(manager.saved.first.username, 'parent@osm-wroclaw');
      expect(manager.saved.first.password, 'secret');
    });

    test('declining to save is not an error', () async {
      final passwords = CredentialManagerSavedPasswords(
        _FakeCredentialManager(error: _code(301)),
      );

      await expectLater(passwords.offerToSave(_login), completes);
    });

    test('a failed save is reported', () async {
      final passwords = CredentialManagerSavedPasswords(
        _FakeCredentialManager(error: _code(302)),
      );

      await expectLater(
        passwords.offerToSave(_login),
        throwsA(isA<SavedPasswordsException>()),
      );
    });

    test('a picked password comes back as a login', () async {
      final passwords = CredentialManagerSavedPasswords(
        _FakeCredentialManager(
          picked: PasswordCredential(
            username: 'parent@osm-wroclaw',
            password: 'secret',
          ),
        ),
      );

      final pick = await passwords.pick();

      expect(pick, isA<SavedLoginPicked>());
      expect((pick as SavedLoginPicked).login, _login);
    });

    test('nothing saved and a cancelled pick are their own answers', () async {
      expect(
        await CredentialManagerSavedPasswords(
          _FakeCredentialManager(error: _code(202)),
        ).pick(),
        isA<NoSavedLogin>(),
      );
      expect(
        await CredentialManagerSavedPasswords(
          _FakeCredentialManager(error: _code(201)),
        ).pick(),
        isA<SavedLoginCancelled>(),
      );
    });

    test('a saved password that is not a BSharp login is reported', () async {
      final passwords = CredentialManagerSavedPasswords(
        _FakeCredentialManager(
          picked: PasswordCredential(username: 'someone', password: 'x'),
        ),
      );

      await expectLater(
        passwords.pick(),
        throwsA(isA<SavedPasswordsException>()),
      );
    });

    test('a failed pick is reported', () async {
      final passwords = CredentialManagerSavedPasswords(
        _FakeCredentialManager(error: _code(204)),
      );

      await expectLater(
        passwords.pick(),
        throwsA(isA<SavedPasswordsException>()),
      );
    });
  });
}
