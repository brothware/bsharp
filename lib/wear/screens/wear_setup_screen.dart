import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/widgets/wear_screen_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

enum _SetupStep { credentials, studentPicker }

class WearSetupScreen extends ConsumerStatefulWidget {
  const WearSetupScreen({super.key});

  @override
  ConsumerState<WearSetupScreen> createState() => _WearSetupScreenState();
}

class _WearSetupScreenState extends ConsumerState<WearSetupScreen> {
  final _schoolController = TextEditingController();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  _SetupStep _step = _SetupStep.credentials;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  List<Student> _students = [];
  int? _selectedStudentId;
  String _password = '';
  String _passwordHash = '';

  @override
  void initState() {
    super.initState();
    unawaited(_checkNeedsSetup());
  }

  Future<void> _checkNeedsSetup() async {
    final accountStorage = ref.read(accountStorageProvider);
    final accounts = await accountStorage.getAccounts();
    if (accounts.isEmpty) return;

    final account = accounts.first;
    _schoolController.text = account.slug;
    _loginController.text = account.login;
    _password = account.password;
    _passwordHash = account.password.isNotEmpty
        ? ref.read(activeDataProviderProvider).hashPassword(account.password)
        : account.legacyPasswordHash ?? '';

    await _loadStudents();
  }

  @override
  void dispose() {
    _schoolController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _validateAndLogin() async {
    final school = _schoolController.text.trim();
    final login = _loginController.text.trim();
    final password = _passwordController.text;

    if (school.isEmpty || login.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = t.setup.fillAllFields);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final provider = ref.read(activeDataProviderProvider);
    _password = password;
    _passwordHash = provider.hashPassword(password);

    final result = await provider.validateCredentials(
      school: school,
      login: login,
      passwordHash: _passwordHash,
    );

    await result.when(
      success: (_) => _loadStudents(),
      failure: (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = _mapFailureMessage(failure);
        });
      },
    );
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final provider = ref.read(activeDataProviderProvider);
    final result = await provider.fetchStudents(
      school: _schoolController.text.trim(),
      login: _loginController.text.trim(),
      passwordHash: _passwordHash,
    );

    if (!mounted) return;

    switch (result) {
      case Failure(:final failure):
        setState(() {
          _isLoading = false;
          _errorMessage = _mapFailureMessage(failure);
        });
      case Success(:final value):
        setState(() {
          _isLoading = false;
          _students = value;
          _step = _SetupStep.studentPicker;
        });

        if (value.length == 1) {
          _selectedStudentId = value.first.id;
          await _finishSetup();
        }
    }
  }

  Future<void> _finishSetup() async {
    if (_selectedStudentId == null) return;

    setState(() => _isLoading = true);

    final school = _schoolController.text.trim();
    final login = _loginController.text.trim();
    final student = _students.firstWhere((s) => s.id == _selectedStudentId);

    final account = ProviderAccount(
      id: const Uuid().v4(),
      providerType: 'mobireg',
      slug: school,
      login: login,
      password: _password,
      students: [
        AccountStudent(
          id: student.id,
          name: student.name,
          surname: student.surname,
        ),
      ],
    );

    final accountStorage = ref.read(accountStorageProvider);
    await accountStorage.saveAccounts([account]);
    await accountStorage.saveActiveSelection(
      ActiveSelection(
        accountId: account.id,
        studentId: _selectedStudentId!,
      ),
    );
    ref
      ..invalidate(providerAccountsProvider)
      ..invalidate(activeSelectionProvider);
    await ref.read(authStateProvider.notifier).completeSetup();
  }

  String _mapFailureMessage(AppFailure failure) {
    return switch (failure) {
      InvalidCredentials() => t.auth.invalidCredentials,
      SchoolNotFound() => t.errors.schoolNotFound,
      NoConnection() => t.errors.noConnection,
      ConnectionTimeout() => t.errors.timeout,
      LicenseExpired() => t.errors.licenseExpired,
      RateLimited() => t.errors.rateLimited,
      _ => t.errors.unknownError,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: WearScreenLayout(
        child: switch (_step) {
          _SetupStep.credentials => _buildCredentialsStep(),
          _SetupStep.studentPicker => _buildStudentPicker(),
        },
      ),
    );
  }

  Widget _buildCredentialsStep() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          Icon(Icons.school, size: 24, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          TextField(
            controller: _schoolController,
            decoration: InputDecoration(
              labelText: t.auth.schoolId,
              isDense: true,
            ),
            textInputAction: TextInputAction.next,
            autocorrect: false,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _loginController,
            decoration: InputDecoration(
              labelText: t.auth.username,
              isDense: true,
            ),
            textInputAction: TextInputAction.next,
            autocorrect: false,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: t.auth.password,
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 16,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _validateAndLogin(),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          FilledButton(
            onPressed: _isLoading ? null : _validateAndLogin,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.setup.loginButton),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentPicker() {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          t.setup.selectStudent,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            itemCount: _students.length,
            itemBuilder: (context, index) {
              final student = _students[index];
              final isSelected = student.id == _selectedStudentId;
              return InkWell(
                onTap: () => setState(() => _selectedStudentId = student.id),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      if (isSelected)
                        Icon(
                          Icons.check,
                          size: 16,
                          color: theme.colorScheme.primary,
                        )
                      else
                        const SizedBox(width: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${student.name} ${student.surname}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        FilledButton(
          onPressed: _selectedStudentId != null && !_isLoading
              ? _finishSetup
              : null,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.setup.finish),
        ),
      ],
    );
  }
}
