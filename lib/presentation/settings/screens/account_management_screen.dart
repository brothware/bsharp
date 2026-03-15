import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/auth/widgets/add_account_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountManagementScreen extends ConsumerWidget {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(providerAccountsProvider);
    final accounts = accountsAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(t.accounts.manageAccounts)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddAccount(context),
        child: const Icon(Icons.add),
      ),
      body: accounts.isEmpty
          ? Center(
              child: Text(
                t.accounts.noAccountsYet,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : ListView.builder(
              itemCount: accounts.length,
              itemBuilder: (context, index) =>
                  _AccountTile(account: accounts[index]),
            ),
    );
  }

  void _navigateToAddAccount(BuildContext context) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(t.accounts.addAccount)),
            body: Center(
              child: AddAccountForm(
                onComplete: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile({required this.account});

  final ProviderAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final studentNames = account.students
        .map((s) => '${s.name} ${s.surname}')
        .join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Text(
            (account.schoolName ?? account.slug).substring(0, 1).toUpperCase(),
          ),
        ),
        title: Text(account.schoolName ?? account.slug),
        subtitle: Text(
          studentNames,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(t.accounts.updateCredentials),
            onTap: () => _navigateToEdit(context),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            title: Text(
              t.accounts.removeAccount,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => _confirmRemove(context, ref),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(t.accounts.editAccount)),
            body: Center(
              child: AddAccountForm(
                existingAccount: account,
                onComplete: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(t.accounts.removeAccount),
          content: Text(t.accounts.removeAccountConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(t.common.cancel),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                ref.read(syncCacheProvider).clear();
                ref.read(syncStatusProvider.notifier).reset();
                await ref
                    .read(providerAccountsProvider.notifier)
                    .removeAccount(account.id);
              },
              child: Text(t.common.delete),
            ),
          ],
        ),
      ),
    );
  }
}
