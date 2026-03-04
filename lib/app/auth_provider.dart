import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/providers/mobireg_data_provider.dart';

final credentialStorageProvider = Provider<CredentialStorage>(
  (ref) => CredentialStorage(),
);

final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final storage = ref.read(credentialStorageProvider);
    final hasCredentials = await storage.hasCredentials();
    final hasStudent = await storage.hasSelectedStudent();
    if (hasCredentials && hasStudent) {
      return AuthState.authenticated;
    }
    return AuthState.unauthenticated;
  }

  Future<void> completeSetup() async {
    state = const AsyncData(AuthState.authenticated);
  }

  Future<void> logout() async {
    final storage = ref.read(credentialStorageProvider);
    await storage.clearAll();
    ref.read(activeDataProviderProvider.notifier).state = MobiregDataProvider();
    ref.read(demoModeProvider.notifier).state = false;
    state = const AsyncData(AuthState.unauthenticated);
  }
}

final selectedStudentIdProvider = FutureProvider<int?>((ref) async {
  final storage = ref.watch(credentialStorageProvider);
  return storage.getSelectedStudentId();
});
