import 'dart:async';

import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/domain/failure_messages.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/auth/reauthenticate.dart';
import 'package:bsharp/wear/widgets/wear_list_item.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
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
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
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
    return Scaffold(
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
              TextField(
                controller: _passwordController,
                obscureText: true,
                autocorrect: false,
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: t.auth.password,
                  errorText: _errorMessage,
                  errorMaxLines: 3,
                  isDense: true,
                ),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(t.auth.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
