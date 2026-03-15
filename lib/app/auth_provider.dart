import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/app/sync_provider.dart';
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
    final selection = await ref.watch(activeSelectionProvider.future);
    if (selection != null) {
      return AuthState.authenticated;
    }
    return AuthState.unauthenticated;
  }

  Future<void> completeSetup() async {
    state = const AsyncData(AuthState.authenticated);
  }

  Future<void> logout() async {
    final accountStorage = ref.read(accountStorageProvider);
    await accountStorage.clearAll();
    final credStorage = ref.read(credentialStorageProvider);
    await credStorage.clearAll();
    ref.read(syncCacheProvider).clear();
    ref.read(activeDataProviderProvider.notifier).value = MobiregDataProvider();
    ref.read(demoModeProvider.notifier).value = false;
    ref.invalidate(providerAccountsProvider);
    ref.invalidate(activeSelectionProvider);
    state = const AsyncData(AuthState.unauthenticated);
  }
}

@Riverpod(keepAlive: true)
Future<int?> selectedStudentId(Ref ref) async {
  final selectionAsync = await ref.watch(activeSelectionProvider.future);
  return selectionAsync?.studentId;
}
