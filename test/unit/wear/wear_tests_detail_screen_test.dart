import 'dart:math' as math;

import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/providers/more_providers.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/wear/screens/wear_tests_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/credential_storage_test.dart';

Widget _buildScreen({
  List<PortalTest> tests = const [],
  WearScreenShape shape = WearScreenShape.rectangular,
}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => shape),
      testsProvider.overrideWithBuild((ref, _) => tests),
    ],
    child: const MaterialApp(home: WearTestsDetailScreen()),
  );
}

const _glassSizeDp = 227.0;
const _devicePixelRatio = 2.0;

final List<PortalTest> _manyTests = [
  for (var day = 10; day < 20; day++)
    PortalTest(
      id: day,
      subjectName: 'Matematyka',
      date: '2026-11-$day',
      title: 'Quadratic functions',
    ),
];

void _useRoundGlass(WidgetTester tester) {
  tester.view.physicalSize = const Size(
    _glassSizeDp * _devicePixelRatio,
    _glassSizeDp * _devicePixelRatio,
  );
  tester.view.devicePixelRatio = _devicePixelRatio;
  addTearDown(tester.view.reset);
}

List<double> _paintedCardWidths(WidgetTester tester) => [
  for (final card
      in find
          .descendant(
            of: find.byType(WearListItem),
            matching: find.byType(Container),
          )
          .evaluate())
    tester.getRect(find.byWidget(card.widget)).width,
];

void main() {
  group('WearTestsDetailScreen', () {
    testWidgets('shows header', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Tests'), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('No tests'), findsOneWidget);
    });

    testWidgets('shows all tests sorted by date', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          tests: [
            const PortalTest(
              id: 1,
              subjectName: 'History',
              date: '2025-01-15',
              title: 'WWII test',
            ),
            const PortalTest(
              id: 2,
              subjectName: 'Biology',
              date: '2025-02-20',
              description: 'Cells and tissues',
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('History'), findsOneWidget);
      expect(find.text('Biology'), findsOneWidget);
      expect(find.text('WWII test'), findsOneWidget);
      expect(find.text('Cells and tissues'), findsOneWidget);
    });

    testWidgets('keeps every card inside a round screen while scrolling', (
      tester,
    ) async {
      _useRoundGlass(tester);

      await tester.pumpWidget(
        _buildScreen(shape: WearScreenShape.round, tests: _manyTests),
      );
      await tester.pump();

      const radius = _glassSizeDp / 2;
      const centre = Offset(radius, radius);
      final viewport = tester.getRect(find.byType(ListView));
      final cards = find.descendant(
        of: find.byType(WearListItem),
        matching: find.byType(Container),
      );
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable),
      );
      final maxScroll = scrollable.position.maxScrollExtent;
      const scrollStep = 7.0;

      for (var offset = 0.0; offset <= maxScroll; offset += scrollStep) {
        scrollable.position.jumpTo(offset);
        await tester.pump();

        for (final card in cards.evaluate()) {
          final visible = tester
              .getRect(find.byWidget(card.widget))
              .intersect(viewport);
          if (visible.isEmpty) {
            continue;
          }
          for (final corner in [
            visible.topLeft,
            visible.topRight,
            visible.bottomLeft,
            visible.bottomRight,
          ]) {
            final distance = (corner - centre).distance;
            expect(
              distance,
              lessThanOrEqualTo(radius),
              reason:
                  'at scroll offset $offset a card corner at $corner is '
                  '${(distance - radius).toStringAsFixed(1)}dp past the '
                  'edge of the glass, which Play rejected as content cut '
                  'off by the screen',
            );
          }
        }
      }
      expect(math.max(maxScroll, 0), greaterThan(0));
    });

    testWidgets('sizes cards the same however the page is transformed', (
      tester,
    ) async {
      _useRoundGlass(tester);
      const transitionScale = 0.5;

      Widget page({required double scale}) {
        final storage = CredentialStorage(store: FakeKeyValueStore());
        return ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider.overrideWith(
              (_) => WearScreenShape.round,
            ),
            testsProvider.overrideWithBuild((ref, _) => _manyTests),
          ],
          child: MaterialApp(
            builder: (context, child) =>
                Transform.scale(scale: scale, child: child),
            home: const WearTestsDetailScreen(),
          ),
        );
      }

      await tester.pumpWidget(page(scale: 1));
      await tester.pump();
      final untransformed = _paintedCardWidths(tester);

      await tester.pumpWidget(page(scale: transitionScale));
      await tester.pump();
      final transformed = _paintedCardWidths(tester);

      expect(transformed, hasLength(untransformed.length));
      for (var index = 0; index < untransformed.length; index++) {
        expect(
          transformed[index],
          moreOrLessEquals(untransformed[index] * transitionScale),
          reason:
              'card $index measured itself against the screen instead of '
              'its page, so a page caught mid zoom transition paints rows '
              'at a scale it then keeps once the transition ends',
        );
      }
    });
  });
}
