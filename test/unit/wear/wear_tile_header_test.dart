import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:bsharp/wear/widgets/wear_tile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildHeader({required WearScreenShape shape, Widget? trailing}) {
  return MaterialApp(
    home: Scaffold(
      body: WearDisplayScope(
        display: WearDisplay(shape: shape, sizeDp: const Size(400, 400)),
        child: WearTileHeader(
          icon: Icons.grade,
          title: 'Grades',
          trailing: trailing,
        ),
      ),
    ),
  );
}

void main() {
  group('WearTileHeader', () {
    testWidgets('rectangular renders Row with icon and title', (tester) async {
      await tester.pumpWidget(_buildHeader(shape: WearScreenShape.rectangular));

      expect(find.byType(Row), findsOneWidget);
      expect(find.text('Grades'), findsOneWidget);
      expect(find.byIcon(Icons.grade), findsOneWidget);
    });

    testWidgets('round renders centered Column with icon and title', (
      tester,
    ) async {
      await tester.pumpWidget(_buildHeader(shape: WearScreenShape.round));

      expect(find.byType(Row), findsNothing);
      expect(find.byIcon(Icons.grade), findsOneWidget);
      expect(find.text('Grades'), findsOneWidget);
    });

    testWidgets('trailing shown in rectangular mode', (tester) async {
      await tester.pumpWidget(
        _buildHeader(
          shape: WearScreenShape.rectangular,
          trailing: const Text('42'),
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('trailing shown in round mode', (tester) async {
      await tester.pumpWidget(
        _buildHeader(shape: WearScreenShape.round, trailing: const Text('42')),
      );

      expect(find.text('42'), findsOneWidget);
    });
  });
}
