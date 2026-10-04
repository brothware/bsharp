import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/core/error/result.dart';
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
