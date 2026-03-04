import 'dart:async';

import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/providers/mobireg_data_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
CredentialStorage credentialStorage(Ref ref) => CredentialStorage();

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
    ref.read(activeDataProviderProvider.notifier).value = MobiregDataProvider();
    ref.read(demoModeProvider.notifier).value = false;
    state = const AsyncData(AuthState.unauthenticated);
  }
}

@Riverpod(keepAlive: true)
Future<int?> selectedStudentId(Ref ref) async {
  final storage = ref.watch(credentialStorageProvider);
  return storage.getSelectedStudentId();
}
