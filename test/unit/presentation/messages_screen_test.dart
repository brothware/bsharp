import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/presentation/messages/providers/messages_providers.dart';
import 'package:bsharp/presentation/messages/screens/messages_screen.dart';

void main() {
  PocztaMessage _msg({int id = 1, String title = 'Test', bool isRead = false}) {
    return PocztaMessage(
      id: id,
      title: title,
      senderName: 'Sender',
      sendTime: DateTime(2026, 2, 27),
      isRead: isRead,
      isStarred: false,
    );
  }

  Widget wrap({
    List<PocztaMessage> inbox = const [],
    List<PocztaMessage> sent = const [],
    List<PocztaMessage> trash = const [],
  }) {
    return ProviderScope(
      overrides: [
        inboxProvider.overrideWith((ref) => inbox),
        sentProvider.overrideWith((ref) => sent),
        trashProvider.overrideWith((ref) => trash),
      ],
      child: const MaterialApp(home: Scaffold(body: MessagesScreen())),
    );
  }

  testWidgets('shows folder tabs', (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('Sent'), findsOneWidget);
    expect(find.text('Trash'), findsOneWidget);
  });

  testWidgets('shows empty inbox state', (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.text('No messages'), findsOneWidget);
  });

  testWidgets('shows inbox messages', (tester) async {
    await tester.pumpWidget(
      wrap(
        inbox: [
          _msg(id: 1, title: 'Pierwsza'),
          _msg(id: 2, title: 'Druga'),
        ],
      ),
    );

    expect(find.text('Pierwsza'), findsOneWidget);
    expect(find.text('Druga'), findsOneWidget);
  });

  testWidgets('shows sent tab empty state', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('Sent'));
    await tester.pumpAndSettle();

    expect(find.text('No sent messages'), findsOneWidget);
  });

  testWidgets('shows trash tab empty state', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('Trash'));
    await tester.pumpAndSettle();

    expect(find.text('Trash is empty'), findsOneWidget);
  });

  testWidgets('shows compose FAB on inbox', (tester) async {
    await tester.pumpWidget(wrap(inbox: [_msg()]));

    expect(find.byIcon(Icons.edit), findsOneWidget);
  });
}
