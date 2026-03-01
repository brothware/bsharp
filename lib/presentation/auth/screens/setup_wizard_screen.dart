import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/core/constants/app_colors.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/remote/auth_service.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/auth/providers/setup_providers.dart';

class SetupWizardScreen extends ConsumerStatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  final _schoolController = TextEditingController();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  List<Student> _students = [];
  int? _selectedStudentId;
  String _passwordHash = '';

  @override
  void dispose() {
    _pageController.dispose();
    _schoolController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  SetupApiState _getApi() {
    final school = _schoolController.text.trim();
    return ref.read(
      setupApiProvider((
        school: school,
        parentLogin: _loginController.text.trim(),
        parentPassHash: _passwordHash,
      )),
    );
  }

  Future<void> _validateSchoolAndCredentials() async {
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

    result.when(
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
          _currentStep = 2;
        });
        _pageController.animateToPage(
          2,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
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

  void _goToCredentialsStep() {
    if (_schoolController.text.trim().isEmpty) {
      setState(() => _errorMessage = t.setup.enterSchoolUrl);
      return;
    }
    setState(() {
      _errorMessage = null;
      _currentStep = 1;
    });
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goBack() {
    final target = _currentStep - 1;
    if (target < 0) return;
    setState(() {
      _errorMessage = null;
      _currentStep = target;
    });
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.setup.title),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _isLoading ? null : _goBack,
              )
            : null,
      ),
      body: Column(
        children: [
          _StepIndicator(currentStep: _currentStep),
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              color: theme.colorScheme.errorContainer,
              child: Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SchoolStep(
                  controller: _schoolController,
                  isLoading: _isLoading,
                  onNext: _goToCredentialsStep,
                ),
                _CredentialsStep(
                  loginController: _loginController,
                  passwordController: _passwordController,
                  isLoading: _isLoading,
                  onNext: _validateSchoolAndCredentials,
                ),
                _StudentStep(
                  students: _students,
                  selectedId: _selectedStudentId,
                  isLoading: _isLoading,
                  onSelected: (id) => setState(() => _selectedStudentId = id),
                  onFinish: _finishSetup,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final labels = [t.setup.schoolStep, t.setup.credentialsStep, t.setup.studentStep];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isActive = index <= currentStep;
          return Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isActive
                      ? AppColors.seaGreen
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[index],
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SchoolStep extends StatelessWidget {
  const _SchoolStep({
    required this.controller,
    required this.isLoading,
    required this.onNext,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.setup.enterSchoolUrl,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            t.setup.enterSchoolUrlSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: t.auth.schoolId,
              hintText: t.auth.schoolIdHint,
              prefixIcon: const Icon(Icons.school),
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            autocorrect: false,
            onSubmitted: (_) => onNext(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isLoading ? null : onNext,
            child: Text(t.setup.next),
          ),
        ],
      ),
    );
  }
}

class _CredentialsStep extends StatelessWidget {
  const _CredentialsStep({
    required this.loginController,
    required this.passwordController,
    required this.isLoading,
    required this.onNext,
  });

  final TextEditingController loginController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.setup.credentialsTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            t.setup.credentialsSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: loginController,
            decoration: InputDecoration(
              labelText: t.auth.username,
              prefixIcon: const Icon(Icons.person),
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            autocorrect: false,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: t.auth.password,
              prefixIcon: const Icon(Icons.lock),
              border: const OutlineInputBorder(),
            ),
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onNext(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isLoading ? null : onNext,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.setup.loginButton),
          ),
        ],
      ),
    );
  }
}

class _StudentStep extends StatelessWidget {
  const _StudentStep({
    required this.students,
    required this.selectedId,
    required this.isLoading,
    required this.onSelected,
    required this.onFinish,
  });

  final List<Student> students;
  final int? selectedId;
  final bool isLoading;
  final ValueChanged<int> onSelected;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.setup.selectStudent,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final isSelected = student.id == selectedId;
                return Card(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        student.name.isNotEmpty ? student.name[0] : '?',
                      ),
                    ),
                    title: Text('${student.name} ${student.surname}'),
                    trailing:
                        isSelected ? const Icon(Icons.check_circle) : null,
                    onTap: () => onSelected(student.id),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: selectedId != null && !isLoading ? onFinish : null,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.setup.finish),
          ),
        ],
      ),
    );
  }
}
