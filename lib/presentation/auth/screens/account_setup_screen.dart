import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/core/constants/app_colors.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/auth/widgets/add_account_form.dart';
import 'package:bsharp/presentation/common/widgets/support_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountSetupScreen extends ConsumerStatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  ConsumerState<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends ConsumerState<AccountSetupScreen> {
  bool _showAddForm = false;

  void _onAccountAdded() {
    setState(() => _showAddForm = false);
  }

  Future<void> _continueToApp() async {
    final accounts = ref.read(providerAccountsProvider).value ?? [];
    if (accounts.isEmpty) return;

    final firstAccount = accounts.first;
    if (firstAccount.students.isEmpty) return;

    await ref
        .read(activeSelectionProvider.notifier)
        .select(
          ActiveSelection(
            accountId: firstAccount.id,
            studentId: firstAccount.students.first.id,
          ),
        );

    if (!mounted) return;
    await ref.read(authStateProvider.notifier).completeSetup();
  }

  Future<void> _handleDemoMode() async {
    await activateDemoMode(ref);
  }

  @override
  Widget build(BuildContext context) {
    if (_showAddForm) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _showAddForm = false),
          ),
          title: Text(t.accounts.addAccount),
        ),
        body: Center(
          child: AddAccountForm(onComplete: _onAccountAdded),
        ),
      );
    }
    return _buildAccountList(context);
  }

  Widget _buildAccountList(BuildContext context) {
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(providerAccountsProvider);
    final accounts = accountsAsync.value ?? [];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.school,
                    size: 64,
                    color: AppColors.seaGreen,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'BSharp',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (accounts.isEmpty) ...[
                    Icon(
                      Icons.account_circle_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.accounts.noAccountsYet,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.accounts.addFirstAccount,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    for (final account in accounts)
                      _AccountCard(
                        account: account,
                        onRemove: () => _removeAccount(account.id),
                      ),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _showAddForm = true),
                    icon: const Icon(Icons.add),
                    label: Text(t.accounts.addAccount),
                  ),
                  if (accounts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _continueToApp,
                      child: Text(t.accounts.continueToApp),
                    ),
                  ],
                  if (accounts.isEmpty) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _handleDemoMode,
                      child: Text(t.auth.demoMode),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Center(child: SupportBadge()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _removeAccount(String accountId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.accounts.removeAccount),
        content: Text(t.accounts.removeAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.common.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(providerAccountsProvider.notifier)
          .removeAccount(accountId);
    }
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.onRemove,
  });

  final ProviderAccount account;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            (account.schoolName ?? account.slug).substring(0, 1).toUpperCase(),
          ),
        ),
        title: Text(account.schoolName ?? account.slug),
        subtitle: Text(
          account.students.map((s) => '${s.name} ${s.surname}').join(', '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.remove_circle_outline,
            color: theme.colorScheme.error,
          ),
          onPressed: onRemove,
        ),
      ),
    );
  }
}
