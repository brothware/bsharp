import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/presentation/messages/screens/messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MalformedPageDataProvider extends DemoDataProvider {
  @override
  Future<List<PocztaMessage>> loadMoreInbox(int skip) async =>
      throw const FormatException('View poczta inbox: expected objects');
}

void main() {
  PocztaMessage msg({int id = 1, String title = 'Test', bool isRead = false}) {
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
        inboxProvider.overrideWithBuild((ref, _) => inbox),
        sentProvider.overrideWithBuild((ref, _) => sent),
        trashProvider.overrideWithBuild((ref, _) => trash),
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
          msg(title: 'Pierwsza'),
          msg(id: 2, title: 'Druga'),
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
    await tester.pumpWidget(wrap(inbox: [msg()]));

    expect(find.byIcon(Icons.edit), findsOneWidget);
  });

  testWidgets('a malformed page of older mail shows an error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inboxProvider.overrideWithBuild((ref, _) => [msg()]),
          sentProvider.overrideWithBuild((ref, _) => const []),
          trashProvider.overrideWithBuild((ref, _) => const []),
          activeDataProviderProvider.overrideWithBuild(
            (ref, _) => _MalformedPageDataProvider(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: MessagesScreen())),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Could not load more messages'), findsOneWidget);
  });
}
