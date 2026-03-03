import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/remote/auth_service.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/auth/providers/setup_providers.dart';
import 'package:bsharp/wear/widgets/wear_screen_layout.dart';

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
  String? _errorMessage;
  List<Student> _students = [];
  int? _selectedStudentId;
  String _passwordHash = '';

  @override
  void initState() {
    super.initState();
    _checkNeedsSetup();
  }

  Future<void> _checkNeedsSetup() async {
    final storage = ref.read(credentialStorageProvider);
    if (!await storage.hasCredentials()) return;

    final school = await storage.getSchool();
    final login = await storage.getLogin();
    final hash = await storage.getPasswordHash();
    if (school == null || login == null || hash == null) return;

    _schoolController.text = school;
    _loginController.text = login;
    _passwordHash = hash;

    await _loadStudents();
  }

  @override
  void dispose() {
    _schoolController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  SetupApiState _getApi() {
    return ref.read(
      setupApiProvider((
        school: _schoolController.text.trim(),
        parentLogin: _loginController.text.trim(),
        parentPassHash: _passwordHash,
      )),
    );
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

    _passwordHash = AuthService.hashPassword(password);

    final api = _getApi();
    final result = await api.syncDataSource.getSettings();

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

    final api = _getApi();
    final result = await api.syncDataSource.getStudents();

    result.when(
      success: (data) {
        final studentsJson = data['ParentStudents'] as List<dynamic>? ?? [];
        final students = studentsJson
            .whereType<Map<String, dynamic>>()
            .map(
              (json) => Student(
                id: json['id'] as int,
                usersEduId: json['users_edu_id'] as int,
                name: json['name'] as String,
                surname: json['surname'] as String,
                sex: Sex.fromString(json['sex'] as String),
              ),
            )
            .toList();

        setState(() {
          _isLoading = false;
          _students = students;
          _step = _SetupStep.studentPicker;
        });

        if (students.length == 1) {
          _selectedStudentId = students.first.id;
          _finishSetup();
        }
      },
      failure: (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = _mapFailureMessage(failure);
        });
      },
    );
  }

  Future<void> _finishSetup() async {
    if (_selectedStudentId == null) return;

    setState(() => _isLoading = true);

    final storage = ref.read(credentialStorageProvider);
    await storage.saveCredentials(
      school: _schoolController.text.trim(),
      login: _loginController.text.trim(),
      passwordHash: _passwordHash,
    );
    await storage.saveSelectedStudentId(_selectedStudentId!);
    await ref.read(authStateProvider.notifier).completeSetup();
  }

  String _mapFailureMessage(AppFailure failure) {
    return switch (failure) {
      InvalidCredentials() => t.auth.invalidCredentials,
      NoConnection() => t.errors.noConnection,
      ConnectionTimeout() => t.errors.timeout,
      LicenseExpired() => t.errors.licenseExpired,
      RateLimited() => t.errors.rateLimited,
      _ => failure.message ?? t.errors.unknownError,
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
            ),
            obscureText: true,
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
