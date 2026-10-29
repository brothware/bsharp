import 'package:bsharp/domain/entities/saved_login.dart';
import 'package:bsharp/domain/saved_passwords.dart';
import 'package:credential_manager/credential_manager.dart';

const _schoolSeparator = '@';
const _saveCancelled = 301;
const _pickCancelled = 201;
const _nothingSaved = 202;

/// A password manager entry has one username, so the school rides along:
/// `login@school`. A school is a URL path segment and cannot hold an `@`.
String savedUsernameOf(SavedLogin login) =>
    '${login.login}$_schoolSeparator${login.school}';

SavedLogin? savedLoginOf(String username, String password) {
  final split = username.lastIndexOf(_schoolSeparator);
  if (split <= 0 || split == username.length - 1) {
    return null;
  }
  return SavedLogin(
    school: username.substring(split + 1),
    login: username.substring(0, split),
    password: password,
  );
}

class CredentialManagerSavedPasswords implements SavedPasswords {
  CredentialManagerSavedPasswords(this._manager);

  final CredentialManager _manager;
  Future<void>? _initialised;

  Future<void> _ready() => _initialised ??= _manager.init(
    preferImmediatelyAvailableCredentials: false,
  );

  @override
  Future<void> offerToSave(SavedLogin login) async {
    await _ready();
    try {
      await _manager.savePasswordCredentials(
        PasswordCredential(
          username: savedUsernameOf(login),
          password: login.password,
        ),
      );
    } on CredentialException catch (error) {
      if (error.code != _saveCancelled) {
        throw SavedPasswordsException('save failed: ${error.message}');
      }
    }
  }

  @override
  Future<SavedLoginPick> pick() async {
    await _ready();
    final Credentials credentials;
    try {
      credentials = await _manager.getCredentials(
        fetchOptions: FetchOptionsAndroid(passwordCredential: true),
      );
    } on CredentialException catch (error) {
      return switch (error.code) {
        _pickCancelled => const SavedLoginCancelled(),
        _nothingSaved => const NoSavedLogin(),
        _ => throw SavedPasswordsException('pick failed: ${error.message}'),
      };
    }
    final password = credentials.passwordCredential;
    if (password == null) {
      return const NoSavedLogin();
    }
    final login = savedLoginOf(
      password.username ?? '',
      password.password ?? '',
    );
    if (login == null || login.password.isEmpty) {
      throw const SavedPasswordsException('saved password is not a login');
    }
    return SavedLoginPicked(login);
  }
}

/// Where no password manager is reachable (iOS, web, desktop) there is
/// nothing to offer to and nothing to pick.
class NoPasswordManager implements SavedPasswords {
  const NoPasswordManager();

  @override
  Future<void> offerToSave(SavedLogin login) async {}

  @override
  Future<SavedLoginPick> pick() async => const NoSavedLogin();
}
