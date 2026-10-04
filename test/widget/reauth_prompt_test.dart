import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/presentation/auth/widgets/reauth_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      home: ReauthPrompt(child: Scaffold(body: Text('Dashboard'))),
    ),
  );
}

void main() {
  testWidgets('asks for the password when a sync needs it, off Messages', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    container.read(reauthRequiredProvider.notifier).value = true;
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('asks once when the flag was raised before the shell', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(reauthRequiredProvider.notifier).value = true;

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    container.read(reauthRequiredProvider.notifier).value = true;
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
