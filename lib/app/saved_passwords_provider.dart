import 'package:bsharp/data/services/credential_manager_saved_passwords.dart';
import 'package:bsharp/domain/saved_passwords.dart';
import 'package:credential_manager/credential_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saved_passwords_provider.g.dart';

@Riverpod(keepAlive: true)
SavedPasswords savedPasswords(Ref ref) =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android
    ? CredentialManagerSavedPasswords(CredentialManager())
    : const NoPasswordManager();
