import 'package:bsharp/core/error/error_messages.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter/material.dart';

class ErrorCard extends StatelessWidget {
  const ErrorCard({required this.failure, this.onRetry, super.key});

  final AppFailure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = errorMessage(failure);
    final canRetry = onRetry != null && isRetryable(failure);

    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconFor(failure),
              color: theme.colorScheme.onErrorContainer,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
            if (canRetry) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(t.common.tryAgain),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AppFailure failure) {
    return switch (failure) {
      NoConnection() => Icons.wifi_off,
      ConnectionTimeout() => Icons.timer_off,
      AuthFailure() => Icons.lock_outline,
      SessionExpired() => Icons.lock_outline,
      RateLimited() => Icons.hourglass_empty,
      LicenseExpired() => Icons.block,
      _ => Icons.error_outline,
    };
  }
}

class ErrorSnackbar {
  const ErrorSnackbar._();

  static void show(
    BuildContext context,
    AppFailure failure, {
    VoidCallback? onRetry,
  }) {
    final message = errorMessage(failure);
    final retry = onRetry;
    final canRetry = retry != null && isRetryable(failure);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: canRetry
            ? SnackBarAction(label: t.common.retry, onPressed: retry)
            : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
