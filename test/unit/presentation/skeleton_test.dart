import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/presentation/common/widgets/skeleton.dart';

void main() {
  group('ShimmerBox', () {
    testWidgets('renders with default size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ShimmerBox(width: 100))),
      );

      expect(find.byType(ShimmerBox), findsOneWidget);
    });

    testWidgets('animates over time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ShimmerBox(width: 100))),
      );

      await tester.pump(const Duration(milliseconds: 750));
      expect(find.byType(ShimmerBox), findsOneWidget);
    });

    testWidgets('uses custom dimensions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerBox(width: 200, height: 32, borderRadius: 8),
          ),
        ),
      );

      expect(find.byType(ShimmerBox), findsOneWidget);
    });
  });

  group('SkeletonListTile', () {
    testWidgets('renders with leading indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SkeletonListTile())),
      );

      expect(find.byType(SkeletonListTile), findsOneWidget);
      expect(find.byType(ShimmerBox), findsNWidgets(3));
    });

    testWidgets('renders without leading indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonListTile(hasLeading: false)),
        ),
      );

      expect(find.byType(ShimmerBox), findsNWidgets(2));
    });
  });

  group('SkeletonCard', () {
    testWidgets('renders with default height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SkeletonCard())),
      );

      expect(find.byType(SkeletonCard), findsOneWidget);
      expect(find.byType(ShimmerBox), findsOneWidget);
    });

    testWidgets('renders with custom height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SkeletonCard(height: 120))),
      );

      expect(find.byType(SkeletonCard), findsOneWidget);
    });
  });

  group('SkeletonList', () {
    testWidgets('renders default number of items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SkeletonList())),
      );

      expect(find.byType(SkeletonListTile), findsNWidgets(6));
    });

    testWidgets('renders custom number of items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SkeletonList(itemCount: 3))),
      );

      expect(find.byType(SkeletonListTile), findsNWidgets(3));
    });
  });
}
