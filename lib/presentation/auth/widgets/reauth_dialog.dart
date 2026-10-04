import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReauthPrompt extends ConsumerStatefulWidget {
  const ReauthPrompt({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ReauthPrompt> createState() => _ReauthPromptState();
}

class _ReauthPromptState extends ConsumerState<ReauthPrompt> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(reauthRequiredProvider)) {
        unawaited(showReauthDialog(context, ref));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(reauthRequiredProvider, (previous, next) {
      if (next && previous != true) {
        unawaited(showReauthDialog(context, ref));
      }
    });
    return widget.child;
  }
}

Future<void> showReauthDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _ReauthDialog(),
  );
}

class _ReauthDialog extends ConsumerStatefulWidget {
  const _ReauthDialog();

  @override
  ConsumerState<_ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends ConsumerState<_ReauthDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;

    final account = ref.read(activeAccountProvider);
    if (account == null) return;

    setState(() => _isSubmitting = true);

    await ref
        .read(providerAccountsProvider.notifier)
        .updateAccount(
          account.copyWith(password: password),
        );

    ref.read(reauthRequiredProvider.notifier).value = false;

    if (!mounted) return;
    Navigator.of(context).pop();
    await ref.read(syncStatusProvider.notifier).sync();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.auth.reauthTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.auth.reauthMessage),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofocus: true,
            decoration: InputDecoration(
              labelText: t.auth.password,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: Text(t.auth.login),
        ),
      ],
    );
  }
}
