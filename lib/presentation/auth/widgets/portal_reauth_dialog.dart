import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showPortalReauthDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _PortalReauthDialog(),
  );
}

class _PortalReauthDialog extends ConsumerStatefulWidget {
  const _PortalReauthDialog();

  @override
  ConsumerState<_PortalReauthDialog> createState() =>
      _PortalReauthDialogState();
}

class _PortalReauthDialogState extends ConsumerState<_PortalReauthDialog> {
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
          account.copyWith(password: password, legacyPasswordHash: null),
        );

    ref.read(portalReauthRequiredProvider.notifier).value = false;

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
