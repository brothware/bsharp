import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/core/constants/app_colors.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/remote/auth_service.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/auth/providers/setup_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _schoolController = TextEditingController();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasStoredCredentials = false;

  @override
  void initState() {
    super.initState();
    _loadStoredCredentials();
  }

  @override
  void dispose() {
    _schoolController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredCredentials() async {
    final storage = ref.read(credentialStorageProvider);
    final results = await Future.wait([
      storage.getSchool(),
      storage.getLogin(),
    ]);
    if (mounted) {
      final school = results[0];
      final login = results[1];
      setState(() {
        _hasStoredCredentials = school != null && login != null;
        if (school != null) _schoolController.text = school;
        if (login != null) _loginController.text = login;
      });
    }
  }

  Future<void> _handleLogin() async {
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

    final passwordHash = AuthService.hashPassword(password);

    final api = ref.read(
      setupApiProvider((
        school: school,
        parentLogin: login,
        parentPassHash: passwordHash,
      )),
    );
    final result = await api.syncDataSource.getSettings();

    if (!mounted) return;

    result.when(
      success: (_) async {
        final storage = ref.read(credentialStorageProvider);
        await storage.saveCredentials(
          school: school,
          login: login,
          passwordHash: passwordHash,
        );

        if (!mounted) return;
        await ref.read(authStateProvider.notifier).credentialsSaved();
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
      InvalidCredentials() => t.auth.invalidCredentials,
      NoConnection() => t.errors.noConnection,
      ConnectionTimeout() => t.errors.timeout,
      LicenseExpired() => t.errors.licenseExpired,
      _ => failure.message ?? t.errors.unknownError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  Icon(
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
                  if (_hasStoredCredentials) ...[
                    Text(
                      t.auth.loginAs(name: _loginController.text),
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
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
                  ],
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
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: t.auth.password,
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    enabled: !_isLoading,
                    onSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t.auth.login),
                  ),
                  if (_hasStoredCredentials) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading ? null : _switchAccount,
                      child: Text(t.auth.switchAccount),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _switchAccount() {
    final storage = ref.read(credentialStorageProvider);
    storage.clearAll().then((_) {
      if (mounted) {
        setState(() {
          _hasStoredCredentials = false;
          _schoolController.clear();
          _loginController.clear();
          _passwordController.clear();
          _errorMessage = null;
        });
      }
    });
  }
}
