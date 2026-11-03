import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/watch_link_provider.dart';
import 'package:bsharp/app/watch_open_permission_provider.dart';
import 'package:bsharp/domain/entities/account_handoff.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WatchSetupScreen extends ConsumerStatefulWidget {
  const WatchSetupScreen({super.key});

  @override
  ConsumerState<WatchSetupScreen> createState() => _WatchSetupScreenState();
}

class _WatchSetupScreenState extends ConsumerState<WatchSetupScreen> {
  String? _sendingAccountId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accounts = [
      for (final account
          in ref.watch(providerAccountsProvider).value ??
              const <ProviderAccount>[])
        if (_canHandOff(account)) account,
    ];
    final watchName = ref.watch(connectedWatchNameProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(t.watchSetup.title)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(t.watchSetup.intro, style: theme.textTheme.bodyLarge),
          ),
          const SizedBox(height: 16),
          if (accounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(t.watchSetup.noAccounts),
            ),
          for (final account in accounts)
            ListTile(
              leading: const Icon(Icons.school),
              title: Text(account.schoolName ?? account.slug),
              subtitle: Text(account.login),
              trailing: _sendingAccountId == account.id
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton.filledTonal(
                      tooltip: t.watchSetup.send,
                      icon: const Icon(Icons.send_to_mobile),
                      onPressed: _sendingAccountId == null
                          ? () => unawaited(_send(account))
                          : null,
                    ),
            ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              t.watchSetup.allowOpenHeading,
              style: theme.textTheme.titleSmall,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: Text(
              watchName == null
                  ? t.watchSetup.allowOpenTitle
                  : t.watchSetup.allowOpenTitleNamed(watch: watchName),
            ),
            subtitle: Text(t.watchSetup.allowOpenSubtitle),
            onTap: () => unawaited(_openAppList()),
          ),
        ],
      ),
    );
  }

  Future<void> _openAppList() async {
    try {
      await ref.read(watchOpenPermissionProvider).openAppList();
    } on PlatformException catch (error, stackTrace) {
      debugPrint('WatchSetupScreen: app list failed: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.watchSetup.allowOpenFailed)));
    }
  }

  Future<String> _handOff(ProviderAccount account) async {
    final link = ref.read(watchLinkProvider);
    try {
      if (!await link.hasConnectedCounterpart()) {
        return t.watchSetup.noWatch;
      }
      final isDelivered = await link.sendAccount(
        AccountHandoff(
          providerType: account.providerType,
          school: account.slug,
          login: account.login,
          password: account.password,
        ),
      );
      return isDelivered ? t.watchSetup.sent : t.watchSetup.watchDidNotAnswer;
    } on PlatformException catch (error, stackTrace) {
      debugPrint('WatchSetupScreen: send failed: $error\n$stackTrace');
      return t.watchSetup.sendFailed;
    }
  }

  bool _canHandOff(ProviderAccount account) =>
      account.password.isNotEmpty &&
      createProviderForType(account.providerType).requiresCredentials;

  Future<void> _send(ProviderAccount account) async {
    setState(() => _sendingAccountId = account.id);
    final String outcome;
    try {
      outcome = await _handOff(account);
    } finally {
      // An error other than a platform one still propagates, but must not
      // leave the button spinning for good.
      if (mounted) {
        setState(() => _sendingAccountId = null);
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(outcome)));
  }
}
