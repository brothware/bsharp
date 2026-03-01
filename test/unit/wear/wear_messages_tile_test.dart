import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/presentation/messages/providers/messages_providers.dart';
import 'package:bsharp/wear/screens/wear_messages_tile.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';

import '../data/credential_storage_test.dart';

PocztaMessage _msg({
  int id = 1,
  String title = 'Subject',
  String sender = 'Jan Kowalski',
  bool isRead = false,
  bool isStarred = false,
}) {
  return PocztaMessage(
    id: id,
    title: title,
    senderName: sender,
    sendTime: DateTime(2025, 6, 15, 10, 0),
    isRead: isRead,
    isStarred: isStarred,
  );
}

Widget _buildTile({List<PocztaMessage> inbox = const []}) {
  final storage = CredentialStorage(storage: FakeFlutterSecureStorage());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider
          .overrideWith((_) => WearScreenShape.rectangular),
      inboxProvider.overrideWith((ref) => inbox),
    ],
    child: const MaterialApp(
      home: Scaffold(body: WearMessagesTile()),
    ),
  );
}

void main() {
  group('WearMessagesTile', () {
    testWidgets('shows empty state when no messages', (tester) async {
      await tester.pumpWidget(_buildTile());
      await tester.pump();

      expect(find.text('No messages'), findsOneWidget);
      expect(find.byIcon(Icons.mail_outline), findsWidgets);
    });

    testWidgets('shows recent messages', (tester) async {
      await tester.pumpWidget(_buildTile(inbox: [
        _msg(id: 1, title: 'Zebranie', sender: 'Anna Nowak'),
        _msg(id: 2, title: 'Wycieczka', sender: 'Jan Kowalski', isRead: true),
      ]));
      await tester.pump();

      expect(find.text('Anna Nowak'), findsOneWidget);
      expect(find.text('Jan Kowalski'), findsOneWidget);
      expect(find.text('Zebranie'), findsOneWidget);
      expect(find.text('Wycieczka'), findsOneWidget);
    });

    testWidgets('shows all messages', (tester) async {
      final messages = List.generate(
        5,
        (i) => _msg(id: i + 1, title: 'Msg $i', isRead: true),
      );

      await tester.pumpWidget(_buildTile(inbox: messages));
      await tester.pump();

      expect(find.text('Msg 0'), findsOneWidget);
      expect(find.text('Msg 1'), findsOneWidget);
      expect(find.text('Msg 2'), findsOneWidget);
    });

    testWidgets('shows unread count badge', (tester) async {
      await tester.pumpWidget(_buildTile(inbox: [
        _msg(id: 1, isRead: false),
        _msg(id: 2, isRead: false),
        _msg(id: 3, isRead: true),
      ]));
      await tester.pump();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('unread messages have bold sender name', (tester) async {
      await tester.pumpWidget(_buildTile(inbox: [
        _msg(id: 1, sender: 'Unread', isRead: false),
      ]));
      await tester.pump();

      final textWidget = tester.widget<Text>(find.text('Unread'));
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });
  });
}
