import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/wear/screens/wear_message_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_messages_list_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/credential_storage_test.dart';

PocztaMessage _msg({
  int id = 1,
  String title = 'Subject',
  String sender = 'Jan Kowalski',
  bool isRead = false,
}) {
  return PocztaMessage(
    id: id,
    title: title,
    senderName: sender,
    sendTime: DateTime(2025, 6, 15, 10),
    isRead: isRead,
    isStarred: false,
  );
}

Widget _buildScreen({List<PocztaMessage> inbox = const []}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.rectangular),
      inboxProvider.overrideWithBuild((ref, _) => inbox),
    ],
    child: const MaterialApp(home: WearMessagesListScreen()),
  );
}

void main() {
  group('WearMessagesListScreen', () {
    testWidgets('shows more than four messages', (tester) async {
      final messages = List.generate(
        6,
        (i) => _msg(id: i + 1, title: 'Msg $i', isRead: true),
      );
      await tester.pumpWidget(_buildScreen(inbox: messages));
      await tester.pump();

      expect(find.text('Msg 0'), findsOneWidget);
      expect(find.text('Msg 4'), findsOneWidget);
      expect(find.text('Msg 5'), findsOneWidget);
    });

    testWidgets('each message opens its detail', (tester) async {
      await tester.pumpWidget(
        _buildScreen(inbox: [_msg(title: 'Zebranie', isRead: true)]),
      );
      await tester.pump();

      await tester.tap(find.text('Zebranie'));
      await tester.pumpAndSettle();

      expect(find.byType(WearMessageDetailScreen), findsOneWidget);
    });

    testWidgets('unread state renders with bold sender name', (tester) async {
      await tester.pumpWidget(
        _buildScreen(inbox: [_msg(sender: 'Unread Sender')]),
      );
      await tester.pump();

      final textWidget = tester.widget<Text>(find.text('Unread Sender'));
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });
  });
}
