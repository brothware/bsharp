import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/app/saved_passwords_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/app/watch_link_provider.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/services/data_layer_watch_link.dart';
import 'package:bsharp/domain/entities/account_handoff.dart';
import 'package:bsharp/domain/failure_messages.dart';
import 'package:bsharp/domain/saved_passwords.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/auth/reauthenticate.dart';
import 'package:bsharp/wear/widgets/wear_list_item.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearReauthPrompt extends ConsumerStatefulWidget {
  const WearReauthPrompt({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<WearReauthPrompt> createState() => _WearReauthPromptState();
}

class _WearReauthPromptState extends ConsumerState<WearReauthPrompt> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(reauthRequiredProvider)) {
        unawaited(_openReauth());
      }
    });
  }

  Future<void> _openReauth() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WearReauthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(reauthRequiredProvider, (previous, next) {
      if (next && previous != true) {
        unawaited(_openReauth());
      }
    });
    return widget.child;
  }
}

class WearReauthScreen extends ConsumerStatefulWidget {
  const WearReauthScreen({super.key});

  @override
  ConsumerState<WearReauthScreen> createState() => _WearReauthScreenState();
}

class _WearReauthScreenState extends ConsumerState<WearReauthScreen> {
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSubmitting = false;
  bool _isTyping = false;
  bool _isWaitingForPhone = false;
  String? _errorMessage;
  StreamSubscription<AccountHandoff>? _phoneAccounts;

  @override
  void dispose() {
    unawaited(_phoneAccounts?.cancel());
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() => _signInAgain(_passwordController.text);

  bool _isActiveAccount(String school, String login) {
    final account = ref.read(activeAccountProvider);
    return account != null && account.slug == school && account.login == login;
  }

  void _listenToPhone() {
    _phoneAccounts ??= ref
        .read(watchLinkProvider)
        .receivedAccounts
        .listen(
          (account) => unawaited(_signInFromPhone(account)),
          onError: (Object error) {
            debugPrint('WearReauthScreen: phone account unreadable: $error');
            setState(
              () => _errorMessage = error is UnsupportedHandoffVersion
                  ? t.watchSetup.updateApp
                  : t.watchSetup.receiveFailed,
            );
          },
        );
    setState(() {
      _errorMessage = null;
      _isWaitingForPhone = true;
    });
  }

  Future<void> _signInFromPhone(AccountHandoff account) async {
    if (!_isActiveAccount(account.school, account.login)) {
      setState(() => _errorMessage = t.watchSetup.differentAccount);
      return;
    }
    await _signInAgain(account.password);
  }

  Future<void> _signInWithSavedPassword() async {
    final SavedLoginPick pick;
    try {
      pick = await ref.read(savedPasswordsProvider).pick();
    } on SavedPasswordsException catch (error) {
      debugPrint('WearReauthScreen: ${error.message}');
      setState(() => _errorMessage = t.watchSetup.savedPasswordFailed);
      return;
    }
    if (!mounted) return;
    switch (pick) {
      case SavedLoginPicked(:final login)
          when _isActiveAccount(login.school, login.login):
        await _signInAgain(login.password);
      case SavedLoginPicked():
        setState(() => _errorMessage = t.watchSetup.differentAccount);
      case NoSavedLogin():
        setState(() => _errorMessage = t.watchSetup.noSavedPassword);
      case SavedLoginCancelled():
        break;
    }
  }

  Future<void> _signInAgain(String password) async {
    if (password.isEmpty || _isSubmitting) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await saveVerifiedPassword(ref, password);
    if (!mounted) {
      return;
    }
    if (result case Failure(:final failure)) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = failureMessage(failure);
      });
      return;
    }

    Navigator.of(context).pop();
    await ref.read(syncStatusProvider.notifier).sync();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WearSwipeDismiss(
      child: Scaffold(
        body: WearScaffold(
          scrollController: _scrollController,
          child: Builder(
            builder: (context) => ListView(
              controller: _scrollController,
              padding: wearListPadding(WearDisplayScope.of(context)),
              children: [
                Text(
                  t.auth.reauthTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  t.auth.reauthMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _isSubmitting ? null : _listenToPhone,
                  child: Text(t.watchSetup.usePhone),
                ),
                if (_isWaitingForPhone)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      t.watchSetup.waitingBody,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => unawaited(_signInWithSavedPassword()),
                  child: Text(t.watchSetup.savedPassword),
                ),
                if (_isTyping) ...[
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    autocorrect: false,
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: t.auth.password,
                      isDense: true,
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(t.auth.login),
                  ),
                ] else
                  // Google asks Wear apps not to take a password on the
                  // watch (WO-P6); typing stays, but only as the last way in.
                  TextButton(
                    onPressed: () => setState(() => _isTyping = true),
                    child: Text(t.watchSetup.typeOnWatch),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
