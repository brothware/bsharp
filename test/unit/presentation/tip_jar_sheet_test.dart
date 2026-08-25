import 'package:bsharp/app/support_provider.dart';
import 'package:bsharp/data/services/tip_jar_service.dart';
import 'package:bsharp/presentation/support/tip_jar_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

final _coffee = ProductDetails(
  id: TipJarService.coffeeId,
  title: 'Coffee',
  description: 'A coffee',
  price: '5,00 zl',
  rawPrice: 5,
  currencyCode: 'PLN',
);

final _meal = ProductDetails(
  id: TipJarService.mealId,
  title: 'Meal',
  description: 'A meal',
  price: '20,00 zl',
  rawPrice: 20,
  currencyCode: 'PLN',
);

Widget _buildSheet({required TipJarState state, required bool isIos}) {
  return ProviderScope(
    overrides: [
      isIosProvider.overrideWithValue(isIos),
      tipJarStateProvider.overrideWith((_) => Stream.value(state)),
    ],
    child: const MaterialApp(home: Scaffold(body: TipJarSheet())),
  );
}

void main() {
  group('TipJarSheet on Android', () {
    testWidgets('offers both store tips and Buy Me a Coffee', (tester) async {
      await tester.pumpWidget(
        _buildSheet(
          state: TipJarAvailable([_coffee, _meal]),
          isIos: false,
        ),
      );
      await tester.pump();

      expect(find.textContaining('Coffee'), findsWidgets);
      expect(find.textContaining('Meal'), findsOneWidget);
      expect(find.text('Buy Me a Coffee'), findsOneWidget);
    });

    testWidgets('falls back to Buy Me a Coffee when no products', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSheet(state: const TipJarUnavailable(), isIos: false),
      );
      await tester.pump();

      expect(find.text('Buy Me a Coffee'), findsOneWidget);
      expect(find.text('Tips are currently unavailable'), findsNothing);
    });
  });

  group('TipJarSheet on iOS', () {
    testWidgets('offers store tips without Buy Me a Coffee', (tester) async {
      await tester.pumpWidget(
        _buildSheet(state: TipJarAvailable([_coffee, _meal]), isIos: true),
      );
      await tester.pump();

      expect(find.textContaining('Meal'), findsOneWidget);
      expect(find.text('Buy Me a Coffee'), findsNothing);
    });

    testWidgets('reports unavailable tips without a link out', (tester) async {
      await tester.pumpWidget(
        _buildSheet(state: const TipJarUnavailable(), isIos: true),
      );
      await tester.pump();

      expect(find.text('Tips are currently unavailable'), findsOneWidget);
      expect(find.text('Buy Me a Coffee'), findsNothing);
    });
  });

  group('supportsStoreTipsProvider', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      test('is enabled on $platform', () {
        debugDefaultTargetPlatformOverride = platform;
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(supportsStoreTipsProvider), isTrue);
      });
    }

    for (final platform in [
      TargetPlatform.linux,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    ]) {
      test('is disabled on $platform', () {
        debugDefaultTargetPlatformOverride = platform;
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(supportsStoreTipsProvider), isFalse);
      });
    }
  });
}
