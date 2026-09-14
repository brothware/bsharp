import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/wear/screens/wear_setup_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/credential_storage_test.dart';

/// The longest failure the setup step can show: four lines on a 432px watch.
class _SchoolNotFoundDataProvider extends DemoDataProvider {
  @override
  Future<Result<String?>> validateCredentials({
    required String school,
    required String login,
    required String passwordHash,
  }) async => const Result.failure(SchoolNotFound());
}

class _RejectingDataProvider extends DemoDataProvider {
  @override
  Future<Result<String?>> validateCredentials({
    required String school,
    required String login,
    required String passwordHash,
  }) async => const Result.failure(InvalidCredentials());
}

Widget _buildApp({
  List<Object> extraOverrides = const [],
  WearScreenShape shape = WearScreenShape.rectangular,
}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => shape),
      ...extraOverrides.cast(),
    ],
    child: const MaterialApp(home: WearSetupScreen()),
  );
}

void main() {
  for (final shape in WearScreenShape.values) {
    group('WearSetupScreen (${shape.name})', () {
      testWidgets('the school step shows exactly one input', (tester) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pump();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('School'), findsWidgets);
      });

      testWidgets(
        'advancing from school to username carries the school value',
        (tester) async {
          await tester.pumpWidget(_buildApp(shape: shape));
          await tester.pump();

          await tester.enterText(find.byType(TextField), 'osm-wroclaw');
          await tester.tap(find.byType(FilledButton));
          await tester.pump();

          expect(find.byType(TextField), findsOneWidget);
          expect(find.text('Username'), findsWidgets);

          await tester.tap(find.byIcon(Icons.arrow_back));
          await tester.pump();

          expect(find.text('osm-wroclaw'), findsOneWidget);
        },
      );

      testWidgets('an empty field shows the fill-in-fields error', (
        tester,
      ) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pump();

        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        expect(find.text('Fill in all fields'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('back from username returns to school without loss', (
        tester,
      ) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'my-school');
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'my-login');
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pump();

        expect(find.text('my-school'), findsOneWidget);
      });

      testWidgets('the primary action is visible and at least 48dp', (
        tester,
      ) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pump();

        final size = tester.getSize(find.byType(FilledButton));
        expect(size.height, greaterThanOrEqualTo(48));
      });

      testWidgets('a login failure renders the mapped credentials message', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            shape: shape,
            extraOverrides: [
              activeDataProviderProvider.overrideWithBuild(
                (ref, _) => _RejectingDataProvider(),
              ),
            ],
          ),
        );
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'osm-wroclaw');
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'baduser');
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'badpass');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(find.text('Invalid credentials'), findsOneWidget);
      });

      testWidgets('the step title stays on one line', (tester) async {
        tester.view.physicalSize = const Size(454, 454);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'osm-wroclaw');
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        final title = tester.widget<Text>(find.text('Username').first);
        expect(title.maxLines, 1);

        final painted = tester.renderObject<RenderBox>(
          find.text('Username').first,
        );
        expect(
          painted.size.height,
          lessThan(32),
          reason: 'the step title wrapped onto a second line',
        );
      });

      testWidgets('the back button clears the step indicator', (tester) async {
        tester.view.physicalSize = const Size(454, 454);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'osm-wroclaw');
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        final back = tester.getRect(find.byIcon(Icons.arrow_back));
        final indicator = tester.getRect(find.text('2/3'));
        expect(
          back.overlaps(indicator),
          isFalse,
          reason: 'the back button is drawn over the step indicator',
        );
      });

      testWidgets('the field does not steal focus on open', (tester) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pump();

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.autofocus, isFalse);
      });
      testWidgets('revealing the password closes the keyboard first', (
        tester,
      ) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'osm-wroclaw');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'parent');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        final hidden = tester.widget<TextField>(find.byType(TextField));
        expect(hidden.obscureText, isTrue);
        expect(hidden.focusNode!.hasFocus, isTrue);

        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pumpAndSettle();

        final revealed = tester.widget<TextField>(find.byType(TextField));
        expect(revealed.obscureText, isFalse);
        expect(
          revealed.focusNode!.hasFocus,
          isFalse,
          reason:
              'the watch keyboard fills the screen and prints what it is '
              'given above the keys, so revealing while it is open puts the '
              'password on the whole display',
        );
      });
      testWidgets('a long failure never pushes the button off the step', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(432, 432);
        tester.view.devicePixelRatio = 2.125;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _buildApp(
            shape: shape,
            extraOverrides: [
              activeDataProviderProvider.overrideWithBuild(
                (ref, _) => _SchoolNotFoundDataProvider(),
              ),
            ],
          ),
        );
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'osm-wroclaw');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'parent');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'wrong');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final button = tester.getRect(find.byType(FilledButton));
        expect(
          button.bottom,
          lessThanOrEqualTo(tester.view.physicalSize.height / 2.125),
          reason:
              'the failure text grew the step until the button fell off the '
              'bottom of the watch, with no way to dismiss it',
        );
      });
    });
  }
}
