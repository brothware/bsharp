import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/failure_messages.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/widgets/wear_fitted_text.dart';
import 'package:bsharp/wear/widgets/wear_pinned_header.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

enum _SetupStep { school, username, password, studentPicker }

const List<_SetupStep> _credentialSteps = [
  _SetupStep.school,
  _SetupStep.username,
  _SetupStep.password,
];

class WearSetupScreen extends ConsumerStatefulWidget {
  const WearSetupScreen({super.key});

  @override
  ConsumerState<WearSetupScreen> createState() => _WearSetupScreenState();
}

class _WearSetupScreenState extends ConsumerState<WearSetupScreen> {
  final _schoolController = TextEditingController();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _fieldStepScrollController = ScrollController();
  final _studentPickerScrollController = ScrollController();

  _SetupStep _step = _SetupStep.school;
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
    _passwordFocus.dispose();
    _fieldStepScrollController.dispose();
    _studentPickerScrollController.dispose();
    super.dispose();
  }

  void _goBack() {
    final index = _credentialSteps.indexOf(_step);
    if (index <= 0) return;
    setState(() {
      _errorMessage = null;
      _step = _credentialSteps[index - 1];
    });
  }

  void _goNext(String value) {
    if (value.trim().isEmpty) {
      _showError(t.setup.fillAllFields);
      return;
    }
    final index = _credentialSteps.indexOf(_step);
    setState(() {
      _errorMessage = null;
      _step = _credentialSteps[index + 1];
    });
  }

  Future<void> _validateAndLogin() async {
    final school = _schoolController.text.trim();
    final login = _loginController.text.trim();
    final password = _passwordController.text;

    if (school.isEmpty || login.isEmpty || password.isEmpty) {
      _showError(t.setup.fillAllFields);
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
        setState(() => _isLoading = false);
        _showError(failureMessage(failure));
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
        setState(() => _isLoading = false);
        _showError(failureMessage(failure));
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

    final account = ProviderAccount(
      id: const Uuid().v4(),
      providerType: 'mobireg',
      slug: school,
      login: login,
      password: _password,
      students: [
        for (final student in _students)
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

  ScrollController get _activeScrollController =>
      _step == _SetupStep.studentPicker
      ? _studentPickerScrollController
      : _fieldStepScrollController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: WearScaffold(
        scrollController: _activeScrollController,
        child: switch (_step) {
          _SetupStep.school => _buildSchoolStep(),
          _SetupStep.username => _buildUsernameStep(),
          _SetupStep.password => _buildPasswordStep(),
          _SetupStep.studentPicker => _buildStudentPicker(),
        },
      ),
    );
  }

  Widget _buildStepHeader({required String label}) {
    final theme = Theme.of(context);
    final stepIndex = _credentialSteps.indexOf(_step);
    final canGoBack = stepIndex > 0;

    return WearPinnedHeader(
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                WearFittedText(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (stepIndex >= 0)
                  Text(
                    '${stepIndex + 1}/${_credentialSteps.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            if (canGoBack)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: 48,
                  child: IconButton(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldStep({
    required String label,
    required TextEditingController controller,
    required String buttonLabel,
    required VoidCallback onSubmit,
    FocusNode? focusNode,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildStepHeader(label: label),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              controller: _fieldStepScrollController,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        focusNode: focusNode,
                        obscureText: obscureText,
                        textAlign: TextAlign.center,
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        onChanged: _clearError,
                        onSubmitted: (_) => onSubmit(),
                        decoration: InputDecoration(
                          labelText: label,
                          isDense: true,
                          suffixIcon: suffixIcon,
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (_errorMessage case final message?)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            message,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _isLoading ? null : onSubmit,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(buttonLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolStep() {
    return _buildFieldStep(
      label: t.setup.schoolStep,
      controller: _schoolController,
      buttonLabel: t.setup.next,
      onSubmit: () => _goNext(_schoolController.text),
    );
  }

  Widget _buildUsernameStep() {
    return _buildFieldStep(
      label: t.auth.username,
      controller: _loginController,
      buttonLabel: t.setup.next,
      onSubmit: () => _goNext(_loginController.text),
    );
  }

  Widget _buildPasswordStep() {
    return _buildFieldStep(
      label: t.auth.password,
      controller: _passwordController,
      buttonLabel: t.setup.loginButton,
      onSubmit: _validateAndLogin,
      obscureText: _obscurePassword,
      focusNode: _passwordFocus,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off : Icons.visibility,
          size: 16,
        ),
        onPressed: _togglePasswordVisibility,
      ),
    );
  }

  /// The message sits under the field, which on a watch is past the bottom of
  /// the glass, so bring it into view rather than leave the user to find it.
  void _showError(String message) {
    setState(() => _errorMessage = message);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _fieldStepScrollController;
      if (!controller.hasClients) return;
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  /// A failure names the step it came from, which may be two steps back, so
  /// it stays until the user does something about it. Typing counts.
  void _clearError(String _) {
    if (_errorMessage == null) return;
    setState(() => _errorMessage = null);
  }

  /// The watch keyboard fills the screen and prints what it is given above
  /// the keys, so revealing the password while it is open puts the password
  /// on the whole display. Close it first; hiding again is harmless.
  void _togglePasswordVisibility() {
    if (_obscurePassword) _passwordFocus.unfocus();
    setState(() => _obscurePassword = !_obscurePassword);
  }

  Widget _buildStudentPicker() {
    final theme = Theme.of(context);

    return Column(
      children: [
        WearPinnedHeader(
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  onPressed: () => setState(() {
                    _errorMessage = null;
                    _step = _SetupStep.password;
                  }),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              Expanded(
                child: Text(
                  t.setup.selectStudent,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48, height: 48),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            controller: _studentPickerScrollController,
            itemCount: _students.length,
            itemBuilder: (context, index) {
              final student = _students[index];
              final isSelected = student.id == _selectedStudentId;
              return InkWell(
                onTap: () => setState(() => _selectedStudentId = student.id),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
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
        SizedBox(
          height: 48,
          child: FilledButton(
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
        ),
      ],
    );
  }
}
