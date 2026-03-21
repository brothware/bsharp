import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/data_sources/local/background_account_cache.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_providers.g.dart';

@Riverpod(keepAlive: true)
AccountStorage accountStorage(Ref ref) => AccountStorage();

@Riverpod(keepAlive: true)
class ProviderAccounts extends _$ProviderAccounts {
  @override
  Future<List<ProviderAccount>> build() async {
    final storage = ref.read(accountStorageProvider);
    return storage.getAccounts();
  }

  Future<void> addAccount(ProviderAccount account) async {
    final storage = ref.read(accountStorageProvider);
    await storage.addAccount(account);
    state = AsyncData(await storage.getAccounts());
    await _syncBackgroundCache();
  }

  Future<void> updateAccount(ProviderAccount account) async {
    final storage = ref.read(accountStorageProvider);
    await storage.updateAccount(account);
    state = AsyncData(await storage.getAccounts());
    await _syncBackgroundCache();
  }

  Future<void> removeAccount(String accountId) async {
    final storage = ref.read(accountStorageProvider);

    final selection = await storage.getActiveSelection();
    final wasActive = selection?.accountId == accountId;

    await storage.removeAccount(accountId);
    final remaining = await storage.getAccounts();
    state = AsyncData(remaining);

    if (!wasActive) {
      await _syncBackgroundCache();
      return;
    }

    if (remaining.isNotEmpty) {
      final nextAccount = remaining.first;
      if (nextAccount.students.isNotEmpty) {
        await ref
            .read(activeSelectionProvider.notifier)
            .select(
              ActiveSelection(
                accountId: nextAccount.id,
                studentId: nextAccount.students.first.id,
              ),
            );
        return;
      }
    }

    await ref.read(activeSelectionProvider.notifier).clear();
  }

  Future<void> reload() async {
    final storage = ref.read(accountStorageProvider);
    state = AsyncData(await storage.getAccounts());
  }

  Future<void> _syncBackgroundCache() async {
    final storage = ref.read(accountStorageProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final cache = BackgroundAccountCache(prefs);
    await cache.syncFrom(storage);
  }
}

@Riverpod(keepAlive: true)
class ActiveSelectionNotifier extends _$ActiveSelectionNotifier {
  @override
  Future<ActiveSelection?> build() async {
    final storage = ref.read(accountStorageProvider);
    return storage.getActiveSelection();
  }

  Future<void> select(ActiveSelection selection) async {
    final storage = ref.read(accountStorageProvider);
    await storage.saveActiveSelection(selection);
    state = AsyncData(selection);
    await _syncBackgroundCache();
  }

  Future<void> clear() async {
    final storage = ref.read(accountStorageProvider);
    await storage.clearActiveSelection();
    state = const AsyncData(null);
    await _syncBackgroundCache();
  }

  Future<void> _syncBackgroundCache() async {
    final storage = ref.read(accountStorageProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final cache = BackgroundAccountCache(prefs);
    await cache.syncFrom(storage);
  }
}

@Riverpod(keepAlive: true)
ProviderAccount? activeAccount(Ref ref) {
  final accounts = ref.watch(providerAccountsProvider).value ?? [];
  final selection = ref.watch(activeSelectionProvider).value;
  if (selection == null) return null;
  final matches = accounts.where((a) => a.id == selection.accountId);
  return matches.isNotEmpty ? matches.first : null;
}

class StudentEntry {
  const StudentEntry({
    required this.account,
    required this.student,
  });

  final ProviderAccount account;
  final AccountStudent student;
}

@Riverpod(keepAlive: true)
List<StudentEntry> allStudents(Ref ref) {
  final accounts = ref.watch(providerAccountsProvider).value ?? [];
  return [
    for (final account in accounts)
      for (final student in account.students)
        StudentEntry(account: account, student: student),
  ];
}
