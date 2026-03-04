import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/presentation/messages/widgets/message_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PocztaMessage msg0({
    int id = 1,
    String title = 'Message subject',
    String senderName = 'Jan Kowalski',
    bool isRead = false,
    bool isStarred = false,
    String? preview,
    List<PocztaAttachment>? files,
  }) {
    return PocztaMessage(
      id: id,
      title: title,
      senderName: senderName,
      sendTime: DateTime(2026, 2, 27, 14, 30),
      isRead: isRead,
      isStarred: isStarred,
      preview: preview,
      files: files,
    );
  }

  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('shows sender name and title', (tester) async {
    await tester.pumpWidget(wrap(MessageTile(message: msg0())));

    expect(find.text('Jan Kowalski'), findsOneWidget);
    expect(find.text('Message subject'), findsOneWidget);
  });

  testWidgets('shows sender initial in avatar', (tester) async {
    await tester.pumpWidget(wrap(MessageTile(message: msg0())));

    expect(find.text('J'), findsOneWidget);
  });

  testWidgets('shows preview text', (tester) async {
    await tester.pumpWidget(
      wrap(MessageTile(message: msg0(preview: 'Preview content'))),
    );

    expect(find.text('Preview content'), findsOneWidget);
  });

  testWidgets('shows star icon when starred', (tester) async {
    await tester.pumpWidget(wrap(MessageTile(message: msg0(isStarred: true))));

    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('does not show star when not starred', (tester) async {
    await tester.pumpWidget(wrap(MessageTile(message: msg0())));

    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('shows attachment icon when files present', (tester) async {
    await tester.pumpWidget(
      wrap(
        MessageTile(
          message: msg0(
            files: [const PocztaAttachment(name: 'doc.pdf', url: 'http://x')],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.attach_file), findsOneWidget);
  });

  testWidgets('triggers onTap callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(MessageTile(message: msg0(), onTap: () => tapped = true)),
    );

    await tester.tap(find.byType(ListTile));
    expect(tapped, isTrue);
  });

  testWidgets('shows date', (tester) async {
    final msg = PocztaMessage(
      id: 1,
      title: 'Test',
      senderName: 'Test',
      sendTime: DateTime(2025, 6, 15, 10),
      isRead: false,
      isStarred: false,
    );
    await tester.pumpWidget(wrap(MessageTile(message: msg)));

    expect(find.text('15.06.2025'), findsOneWidget);
  });
}
