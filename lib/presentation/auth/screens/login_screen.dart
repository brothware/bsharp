import 'dart:async';

import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/core/constants/app_colors.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/widgets/support_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  List<Student>? _students;
  int? _selectedStudentId;
  String _passwordHash = '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadStoredCredentials());
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

    final provider = ref.read(activeDataProviderProvider);
    _passwordHash = provider.hashPassword(password);

    final result = await provider.validateCredentials(
      school: school,
      login: login,
      passwordHash: _passwordHash,
    );

    if (!mounted) return;

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
    final provider = ref.read(activeDataProviderProvider);

    try {
      final students = await provider.fetchStudents(
        school: _schoolController.text.trim(),
        login: _loginController.text.trim(),
        passwordHash: _passwordHash,
      );

      if (!mounted) return;

      if (students.length == 1) {
        await _finishLogin(students.first.id);
        return;
      }

      setState(() {
        _isLoading = false;
        _students = students;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = t.errors.unknownError;
      });
    }
  }

  Future<void> _finishLogin(int studentId) async {
    final storage = ref.read(credentialStorageProvider);
    await storage.saveCredentials(
      school: _schoolController.text.trim(),
      login: _loginController.text.trim(),
      passwordHash: _passwordHash,
    );
    await storage.saveSelectedStudentId(studentId);

    if (!mounted) return;
    await ref.read(authStateProvider.notifier).completeSetup();
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

  Future<void> _handleDemoMode() async {
    setState(() => _isLoading = true);
    await activateDemoMode(ref);
  }

  Future<void> _switchAccount() async {
    final storage = ref.read(credentialStorageProvider);
    await storage.clearAll();
    if (mounted) {
      setState(() {
        _hasStoredCredentials = false;
        _schoolController.clear();
        _loginController.clear();
        _passwordController.clear();
        _errorMessage = null;
        _students = null;
        _selectedStudentId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_students != null) {
      return _buildStudentPicker(context);
    }
    return _buildLoginForm(context);
  }

  Widget _buildLoginForm(BuildContext context) {
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
                  const Icon(Icons.school, size: 64, color: AppColors.seaGreen),
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
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _handleDemoMode,
                    child: Text(t.auth.demoMode),
                  ),
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

  Widget _buildStudentPicker(BuildContext context) {
    final theme = Theme.of(context);
    final students = _students!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading
              ? null
              : () => setState(() {
                  _students = null;
                  _selectedStudentId = null;
                }),
        ),
        title: Text(t.setup.selectStudent),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final isSelected = student.id == _selectedStudentId;
                        return Card(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer
                              : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                student.name.isNotEmpty ? student.name[0] : '?',
                              ),
                            ),
                            title: Text('${student.name} ${student.surname}'),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle)
                                : null,
                            onTap: () =>
                                setState(() => _selectedStudentId = student.id),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _selectedStudentId != null && !_isLoading
                        ? () => _finishLogin(_selectedStudentId!)
                        : null,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t.setup.finish),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
