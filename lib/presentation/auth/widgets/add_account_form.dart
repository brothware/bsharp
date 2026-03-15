import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class _ProviderOption {
  const _ProviderOption({
    required this.id,
    required this.displayName,
    required this.icon,
  });

  final String id;
  final String displayName;
  final IconData icon;
}

const _availableProviders = [
  _ProviderOption(
    id: 'mobireg',
    displayName: 'Mobireg',
    icon: Icons.school,
  ),
];

class AddAccountForm extends ConsumerStatefulWidget {
  const AddAccountForm({this.existingAccount, this.onComplete, super.key});

  final ProviderAccount? existingAccount;
  final VoidCallback? onComplete;

  @override
  ConsumerState<AddAccountForm> createState() => _AddAccountFormState();
}

class _AddAccountFormState extends ConsumerState<AddAccountForm> {
  final _schoolController = TextEditingController();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedProviderType;

  bool get _isEditing => widget.existingAccount != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _selectedProviderType = widget.existingAccount!.providerType;
      _schoolController.text = widget.existingAccount!.slug;
      _loginController.text = widget.existingAccount!.login;
    }
  }

  @override
  void dispose() {
    _schoolController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final school = _schoolController.text.trim();
    final login = _loginController.text.trim();
    final password = _passwordController.text;

    if (school.isEmpty) {
      setState(() => _errorMessage = t.auth.enterSchoolId);
      return;
    }
    if (login.isEmpty) {
      setState(() => _errorMessage = t.auth.enterLogin);
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = t.auth.enterPassword);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final provider = createProviderForType(_selectedProviderType!);
    final passwordHash = provider.hashPassword(password);

    final result = await provider.validateCredentials(
      school: school,
      login: login,
      passwordHash: passwordHash,
    );

    if (!mounted) return;

    await result.when(
      success: (schoolName) async {
        final students = await provider.fetchStudents(
          school: school,
          login: login,
          passwordHash: passwordHash,
        );

        if (!mounted) return;

        final accountStudents = students
            .map(
              (s) => AccountStudent(
                id: s.id,
                name: s.name,
                surname: s.surname,
              ),
            )
            .toList();

        final account = ProviderAccount(
          id: _isEditing ? widget.existingAccount!.id : const Uuid().v4(),
          providerType: _selectedProviderType!,
          slug: school,
          login: login,
          passwordHash: passwordHash,
          schoolName: schoolName ?? school,
          students: accountStudents,
        );

        final notifier = ref.read(providerAccountsProvider.notifier);
        if (_isEditing) {
          await notifier.updateAccount(account);
        } else {
          await notifier.addAccount(account);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.accounts.accountAddedSuccess)),
        );

        widget.onComplete?.call();
      },
      failure: (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = _mapFailureMessage(failure);
        });
      },
    );
  }

  String _mapFailureMessage(AppFailure failure) {
    return switch (failure) {
      InvalidCredentials() => t.accounts.credentialsInvalid,
      NoConnection() => t.errors.noConnection,
      ConnectionTimeout() => t.errors.timeout,
      LicenseExpired() => t.errors.licenseExpired,
      _ => failure.message ?? t.errors.unknownError,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedProviderType == null) {
      return _buildProviderSelection(context);
    }
    return _buildCredentialsForm(context);
  }

  Widget _buildProviderSelection(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.accounts.selectProvider,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            for (final option in _availableProviders)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(option.icon),
                  title: Text(option.displayName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      setState(() => _selectedProviderType = option.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsForm(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? t.accounts.editAccount : t.accounts.addAccount,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            TextField(
              controller: _schoolController,
              decoration: InputDecoration(
                labelText: t.auth.schoolId,
                hintText: t.auth.schoolIdHint,
                prefixIcon: const Icon(Icons.domain),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _loginController,
              decoration: InputDecoration(
                labelText: t.auth.username,
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: t.auth.password,
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isEditing
                          ? t.accounts.updateCredentials
                          : t.accounts.addAccount,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
