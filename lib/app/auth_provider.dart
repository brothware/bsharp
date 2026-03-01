import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/data_sources/remote/auth_service.dart';

final credentialStorageProvider = Provider<CredentialStorage>(
  (ref) => CredentialStorage(),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => throw UnimplementedError(
    'authServiceProvider must be overridden after login',
  ),
);

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final storage = ref.read(credentialStorageProvider);
    final hasCredentials = await storage.hasCredentials();
    if (!hasCredentials) {
      return AuthState.unauthenticated;
    }
    final hasStudent = await storage.hasSelectedStudent();
    if (!hasStudent) {
      return AuthState.needsSetup;
    }
    return AuthState.authenticated;
  }

  Future<void> completeSetup() async {
    state = const AsyncData(AuthState.authenticated);
  }

  Future<void> credentialsSaved() async {
    state = const AsyncData(AuthState.needsSetup);
  }

  Future<void> logout() async {
    final storage = ref.read(credentialStorageProvider);
    await storage.clearAll();
    state = const AsyncData(AuthState.unauthenticated);
  }
}

final selectedStudentIdProvider = FutureProvider<int?>((ref) async {
  final storage = ref.watch(credentialStorageProvider);
  return storage.getSelectedStudentId();
});
