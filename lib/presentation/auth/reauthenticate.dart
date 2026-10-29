import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/app/saved_passwords_provider.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/domain/entities/saved_login.dart';
import 'package:bsharp/domain/saved_passwords.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<Result<void>> saveVerifiedPassword(
  WidgetRef ref,
  String password,
) async {
  final account =
      ref.read(activeAccountProvider) ??
      (throw StateError('No active account to sign in again'));
  final probe = await ref
      .read(activeDataProviderProvider)
      .probeAccount(
        school: account.slug,
        login: account.login,
        password: password,
      );
  if (probe case Failure(:final failure)) {
    return Result.failure(failure);
  }
  await ref
      .read(providerAccountsProvider.notifier)
      .updateAccount(account.copyWith(password: password));
  ref.read(reauthRequiredProvider.notifier).value = false;
  return const Result.success(null);
}

/// Offers a login that has just been verified to the password manager, so a
/// watch on the same Google account can sign in without typing (WO-P6). The
/// sign-in itself has already succeeded, so a failure here is only logged.
Future<void> offerToSaveLogin(WidgetRef ref, ProviderAccount account) async {
  try {
    await ref
        .read(savedPasswordsProvider)
        .offerToSave(
          SavedLogin(
            school: account.slug,
            login: account.login,
            password: account.password,
          ),
        );
  } on SavedPasswordsException catch (error) {
    debugPrint('offerToSaveLogin: ${error.message}');
  }
}
