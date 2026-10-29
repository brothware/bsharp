import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/saved_passwords_provider.dart';
import 'package:bsharp/app/watch_link_provider.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/services/data_layer_watch_link.dart';
import 'package:bsharp/domain/entities/account_handoff.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/domain/entities/saved_login.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/failure_messages.dart';
import 'package:bsharp/domain/saved_passwords.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/wear_phone.dart';
import 'package:bsharp/wear/wear_text_input.dart';
import 'package:bsharp/wear/widgets/wear_fitted_text.dart';
import 'package:bsharp/wear/widgets/wear_list_item.dart';
import 'package:bsharp/wear/widgets/wear_pinned_header.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

enum _SetupStep {
  welcome,
  provider,
  phone,
  school,
  username,
  password,
  studentPicker,
}

const List<_SetupStep> _credentialSteps = [
  _SetupStep.school,
  _SetupStep.username,
  _SetupStep.password,
];

class WearSetupScreen extends ConsumerStatefulWidget {
  const WearSetupScreen({super.key, this.addingAnother = false});

  /// Opened from settings to add a second account rather than to set the
  /// watch up, so there is nothing to welcome and nothing to prefill.
  final bool addingAnother;

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

  _SetupStep _step = _SetupStep.welcome;

  /// Whether the saved accounts have been read yet. Until they have, the
  /// screen cannot know whether it is setting an account up or re-authorising
  /// one, and offering the provider step in the meantime asks a returning user
  /// a question they already answered.
  bool _knowsWhetherSetUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  List<Student> _students = [];
  int? _selectedStudentId;
  String _password = '';
  StreamSubscription<AccountHandoff>? _phoneAccounts;
  _SetupStep? _signedInFrom;
  int _signInAttempt = 0;
  bool _isPickingSavedPassword = false;
  bool _isPhoneUnreachable = false;

  @override
  void initState() {
    super.initState();
    if (widget.addingAnother) {
      _knowsWhetherSetUp = true;
      _step = _SetupStep.provider;
      return;
    }
    unawaited(_checkNeedsSetup());
  }

  Future<void> _checkNeedsSetup() async {
    final accountStorage = ref.read(accountStorageProvider);
    final accounts = await accountStorage.getAccounts();
    if (!mounted) return;

    if (accounts.isEmpty) {
      setState(() => _knowsWhetherSetUp = true);
      return;
    }

    final account = accounts.first;
    setState(() {
      _knowsWhetherSetUp = true;
      _step = _SetupStep.school;
    });
    _schoolController.text = account.slug;
    _loginController.text = account.login;
    _password = account.password;
    _signedInFrom = null;
    if (_password.isEmpty) {
      return;
    }

    await _loadStudents();
  }

  @override
  void dispose() {
    unawaited(_phoneAccounts?.cancel());
    _schoolController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    _fieldStepScrollController.dispose();
    _studentPickerScrollController.dispose();
    super.dispose();
  }

  _SetupStep? get _previousStep {
    final credentialIndex = _credentialSteps.indexOf(_step);
    return switch (_step) {
      _SetupStep.welcome => null,
      _SetupStep.provider => widget.addingAnother ? null : _SetupStep.welcome,
      _SetupStep.phone =>
        widget.addingAnother ? _SetupStep.provider : _SetupStep.welcome,
      _SetupStep.studentPicker => _signedInFrom ?? _SetupStep.password,
      _ when credentialIndex == 0 => _SetupStep.provider,
      _ => _credentialSteps[credentialIndex - 1],
    };
  }

  void _goBack() {
    final previous = _previousStep;
    if (previous == null) {
      _leaveSetup();
      return;
    }
    if (_step == _SetupStep.phone) {
      _stopListeningToPhone();
    }
    _signInAttempt++;
    setState(() {
      _isLoading = false;
      _errorMessage = null;
      _step = previous;
    });
  }

  void _leaveSetup() {
    if (widget.addingAnother) {
      Navigator.of(context).pop();
    } else {
      unawaited(SystemNavigator.pop());
    }
  }

  void _listenToPhone() {
    _phoneAccounts ??= ref
        .read(watchLinkProvider)
        .receivedAccounts
        .listen(
          (account) => unawaited(_signInFromPhone(account)),
          onError: _onPhoneAccountUnreadable,
        );
    unawaited(_openOnPhone());
    setState(() {
      _errorMessage = null;
      _step = _SetupStep.phone;
    });
  }

  Future<void> _openOnPhone() async {
    setState(() => _isPhoneUnreachable = false);
    final isOpened = await openSetUpWatchOnPhone();
    if (mounted && !isOpened && _step == _SetupStep.phone) {
      setState(() => _isPhoneUnreachable = true);
    }
  }

  void _stopListeningToPhone() {
    unawaited(_phoneAccounts?.cancel());
    _phoneAccounts = null;
  }

  void _onPhoneAccountUnreadable(Object error, StackTrace stackTrace) {
    debugPrint('WearSetupScreen: phone account unreadable: $error');
    _showError(
      error is UnsupportedHandoffVersion
          ? t.watchSetup.updateApp
          : t.watchSetup.receiveFailed,
    );
  }

  Future<void> _signInFromPhone(AccountHandoff account) async {
    if (_step != _SetupStep.phone) return;
    await _signInWith(
      providerType: account.providerType,
      login: SavedLogin(
        school: account.school,
        login: account.login,
        password: account.password,
      ),
      from: _SetupStep.phone,
    );
  }

  Future<void> _signInWithSavedPassword() async {
    if (_isPickingSavedPassword) return;
    _isPickingSavedPassword = true;
    final SavedLoginPick pick;
    try {
      pick = await ref.read(savedPasswordsProvider).pick();
    } on SavedPasswordsException catch (error) {
      debugPrint('WearSetupScreen: ${error.message}');
      if (mounted) {
        _showError(t.watchSetup.savedPasswordFailed);
      }
      return;
    } finally {
      _isPickingSavedPassword = false;
    }
    if (!mounted) return;
    switch (pick) {
      case SavedLoginPicked(:final login):
        await _signInWith(
          providerType: allKnownProviders()
              .firstWhere((provider) => provider.requiresCredentials)
              .id,
          login: login,
          from: _step,
        );
      case NoSavedLogin():
        _showError(t.watchSetup.noSavedPassword);
      case SavedLoginCancelled():
        break;
    }
  }

  Future<void> _signInWith({
    required String providerType,
    required SavedLogin login,
    required _SetupStep from,
  }) async {
    if (_isLoading) return;
    if (ref.read(activeDataProviderProvider).id != providerType) {
      ref.read(activeDataProviderProvider.notifier).value =
          createProviderForType(providerType);
    }
    _schoolController.text = login.school;
    _loginController.text = login.login;
    _password = login.password;
    _signedInFrom = from;
    await _loadStudents();
  }

  Future<void> _selectProvider(SchoolDataProvider provider) async {
    // Re-picking the backend that is already active would throw away whatever
    // it holds - a portal session, for one - to gain an identical instance.
    if (ref.read(activeDataProviderProvider).id != provider.id) {
      ref.read(activeDataProviderProvider.notifier).value = provider;
    }

    if (provider.requiresCredentials) {
      setState(() {
        _errorMessage = null;
        _step = _SetupStep.school;
      });
      return;
    }

    setState(() => _isLoading = true);
    await activateDemoMode(ref);
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

    _password = password;
    _signedInFrom = null;
    await _loadStudents();
  }

  Future<void> _loadStudents() async {
    final attempt = ++_signInAttempt;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final provider = ref.read(activeDataProviderProvider);
    final result = await provider.probeAccount(
      school: _schoolController.text.trim(),
      login: _loginController.text.trim(),
      password: _password,
    );

    // The wearer may have backed out while the server was answering; a
    // late answer must not pull them forward into a sign-in they left.
    if (!mounted || attempt != _signInAttempt) return;

    switch (result) {
      case Failure(:final failure):
        setState(() => _isLoading = false);
        _showError(failureMessage(failure));
      case Success(:final value):
        setState(() {
          _isLoading = false;
          _students = value.students;
          _step = _SetupStep.studentPicker;
        });

        if (value.students.length == 1) {
          _selectedStudentId = value.students.single.id;
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
    // Append: replacing the list is what stopped a watch holding more than
    // one account, whoever the provider was.
    await accountStorage.addAccount(account);
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
    return PopScope(
      canPop: _previousStep == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _goBack();
        }
      },
      child: WearSwipeDismiss(
        onDismiss: _goBack,
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: WearScaffold(
        scrollController: _activeScrollController,
        child: switch (_step) {
          _SetupStep.welcome =>
            _knowsWhetherSetUp ? _buildWelcomeStep() : const SizedBox.shrink(),
          _SetupStep.provider =>
            _knowsWhetherSetUp ? _buildProviderStep() : const SizedBox.shrink(),
          _SetupStep.phone => _buildPhoneStep(),
          _SetupStep.school => _buildSchoolStep(),
          _SetupStep.username => _buildUsernameStep(),
          _SetupStep.password => _buildPasswordStep(),
          _SetupStep.studentPicker => _buildStudentPicker(),
        },
      ),
    );
  }

  static const _stepHeaderButtonWidth = 48.0;
  static const _stepHeaderMinHeight = 32.0;

  Widget _buildStepHeader({required String label, int maxLines = 1}) {
    final theme = Theme.of(context);
    final stepIndex = _credentialSteps.indexOf(_step);
    final canGoBack = stepIndex > 0;

    // A back arrow is a touch target, so the header is tall enough to give
    // it the full 48dp (WO-V2) rather than the two lines of text it holds.
    return WearPinnedHeader(
      minHeight: canGoBack ? _stepHeaderButtonWidth : _stepHeaderMinHeight,
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              // Clear of the back button on both sides, so the label stays
              // centred on the step rather than on whatever space is left.
              // Only when there is one: a step without a back button was
              // giving up 96dp of a 177dp watch and eliding its heading to
              // fit what was left.
              padding: EdgeInsets.symmetric(
                horizontal: canGoBack ? _stepHeaderButtonWidth : 0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WearFittedText(
                    label,
                    maxLines: maxLines,
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
            ),
            if (canGoBack)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: _stepHeaderButtonWidth,
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
    // A secret stays on the masked in-app field: the system input screen shows
    // what it is given, and on a watch that is the whole display.
    final useSystemInput = !obscureText;
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
                        readOnly: useSystemInput,
                        onTap: useSystemInput
                            ? () => _editOnSystemInput(controller, label)
                            : null,
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

  Widget _buildWelcomeStep() {
    final theme = Theme.of(context);

    // Scrollable: two buttons and three lines of prose do not fit the
    // shorter watches, and an overflow is a worse answer than a scroll. The
    // padding is what lets the last button be brought up off the bezel.
    return Builder(
      builder: (context) => ListView(
        controller: _fieldStepScrollController,
        padding: wearListPadding(WearDisplayScope.of(context)),
        shrinkWrap: true,
        children: [
          Text(
            t.accounts.noAccountsYet,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            t.accounts.addFirstAccount,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _listenToPhone,
            child: Text(t.watchSetup.usePhone),
          ),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: _isLoading
                ? null
                : () => unawaited(_signInWithSavedPassword()),
            child: Text(t.watchSetup.savedPassword),
          ),
          const SizedBox(height: 6),
          // Beside the way in, as on the phone: demo is not a school anyone
          // holds an account with, so it does not belong among the providers.
          OutlinedButton(
            onPressed: _isLoading ? null : () => unawaited(_startDemo()),
            child: Text(t.auth.demoMode),
          ),
          if (_errorMessage case final message?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          // Google asks Wear apps not to take a password on the watch
          // (WO-P6); typing stays possible, but only as the last way in.
          TextButton(
            onPressed: () => setState(() {
              _errorMessage = null;
              _step = _SetupStep.provider;
            }),
            child: Text(t.watchSetup.typeOnWatch),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneStep() {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildStepHeader(label: t.watchSetup.waitingTitle),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            controller: _fieldStepScrollController,
            children: [
              Text(
                t.watchSetup.waitingBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              if (_isPhoneUnreachable)
                Text(
                  t.watchSetup.phoneUnreachable,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                const Center(child: CircularProgressIndicator()),
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
      ],
    );
  }

  Future<void> _startDemo() async {
    setState(() => _isLoading = true);
    await activateDemoMode(ref);
  }

  Widget _buildProviderStep() {
    final theme = Theme.of(context);

    return Column(
      children: [
        // The phone's "Choose your e-gradebook provider" does not fit a watch
        // header on one line and the header is only tall enough for one, so
        // it came out as "Choo...". The list underneath names the providers,
        // so the heading only has to say what the list is for.
        _buildStepHeader(label: t.accounts.addAccount),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            controller: _fieldStepScrollController,
            children: [
              if (widget.addingAnother) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton(
                    onPressed: _isLoading ? null : _listenToPhone,
                    child: Text(t.watchSetup.usePhone),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => unawaited(_signInWithSavedPassword()),
                    child: Text(t.watchSetup.savedPassword),
                  ),
                ),
              ],
              for (final provider in allKnownProviders().where(
                (provider) => provider.requiresCredentials,
              ))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton.tonal(
                    onPressed: _isLoading
                        ? null
                        : () => unawaited(_selectProvider(provider)),
                    child: Text(
                      provider.displayName,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
            ],
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

  Future<void> _editOnSystemInput(
    TextEditingController controller,
    String label,
  ) async {
    final typed = await requestWearTextInput(
      label: label,
      text: controller.text,
    );
    if (typed == null || !mounted) return;

    controller.text = typed;
    _clearError(typed);
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
                  onPressed: _goBack,
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
