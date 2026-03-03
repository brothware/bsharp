import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bsharp/app/support_provider.dart';
import 'package:bsharp/data/services/tip_jar_service.dart';
import 'package:bsharp/l10n/strings.g.dart';

void showTipJarSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    builder: (_) => const TipJarSheet(),
  );
}

class TipJarSheet extends ConsumerStatefulWidget {
  const TipJarSheet({super.key});

  @override
  ConsumerState<TipJarSheet> createState() => _TipJarSheetState();
}

class _TipJarSheetState extends ConsumerState<TipJarSheet> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(tipJarStateProvider, (previous, next) {
      final state = next.valueOrNull;
      if (state == null) return;

      switch (state) {
        case TipJarPurchased():
          Navigator.of(context).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.support.purchaseSuccess)));
        case TipJarFailed(:final message):
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stateAsync = ref.watch(tipJarStateProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.support.tipJar, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              t.support.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            stateAsync.when(
              data: (state) => _buildContent(state, theme),
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => Text(t.support.productsUnavailable),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(TipJarState state, ThemeData theme) {
    return switch (state) {
      TipJarLoading() => const Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
      TipJarAvailable(:final products) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final product in products)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FilledButton.tonal(
                onPressed: () {
                  final service = ref.read(tipJarServiceProvider);
                  service?.purchase(product);
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(
                  '${_productLabel(product.id)} — ${product.price}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
        ],
      ),
      TipJarUnavailable() => Text(t.support.productsUnavailable),
      TipJarPurchasing() => const Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
      TipJarPurchased() => Text(t.support.purchaseSuccess),
      TipJarFailed() => Text(t.support.purchaseFailed),
    };
  }

  String _productLabel(String productId) {
    return switch (productId) {
      TipJarService.coffeeId => t.support.tipCoffee,
      TipJarService.mealId => t.support.tipMeal,
      _ => productId,
    };
  }
}
