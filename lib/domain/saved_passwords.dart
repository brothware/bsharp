import 'package:bsharp/domain/entities/saved_login.dart';

sealed class SavedLoginPick {
  const SavedLoginPick();
}

final class SavedLoginPicked extends SavedLoginPick {
  const SavedLoginPicked(this.login);

  final SavedLogin login;
}

final class NoSavedLogin extends SavedLoginPick {
  const NoSavedLogin();
}

final class SavedLoginCancelled extends SavedLoginPick {
  const SavedLoginCancelled();
}

class SavedPasswordsException implements Exception {
  const SavedPasswordsException(this.message);

  final String message;

  @override
  String toString() => 'SavedPasswordsException: $message';
}

abstract interface class SavedPasswords {
  /// Offers to keep [login] in the user's password manager. Declining is a
  /// normal answer and returns quietly; a failure throws.
  Future<void> offerToSave(SavedLogin login);

  Future<SavedLoginPick> pick();
}
