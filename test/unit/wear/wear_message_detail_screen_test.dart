import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/wear/screens/wear_message_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/credential_storage_test.dart';

PocztaMessage _msg({
  int id = 1,
  String title = 'Test Subject',
  String sender = 'Jan Kowalski',
  String? content,
  List<PocztaAttachment>? files,
}) {
  return PocztaMessage(
    id: id,
    title: title,
    senderName: sender,
    sendTime: DateTime(2025, 6, 15, 10),
    isRead: true,
    isStarred: false,
    content: content,
    files: files,
  );
}

Widget _buildScreen({required PocztaMessage message}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.rectangular),
      activeDataProviderProvider.overrideWithBuild(
        (ref, _) => DemoDataProvider(),
      ),
      isTranslationAvailableProvider.overrideWithValue(false),
    ],
    child: MaterialApp(home: WearMessageDetailScreen(message: message)),
  );
}

void main() {
  group('WearMessageDetailScreen', () {
    testWidgets('shows sender name and title', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          message: _msg(title: 'Meeting Tomorrow', sender: 'Anna Nowak'),
        ),
      );
      await tester.pump();

      expect(find.text('Anna Nowak'), findsOneWidget);
      expect(find.text('Meeting Tomorrow'), findsOneWidget);
    });

    testWidgets('shows date', (tester) async {
      await tester.pumpWidget(_buildScreen(message: _msg()));
      await tester.pump();

      expect(find.text('15.06.2025 10:00'), findsOneWidget);
    });

    testWidgets('shows content when available', (tester) async {
      await tester.pumpWidget(
        _buildScreen(message: _msg(content: '<p>Hello world</p>')),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('sender scrolls out of view with the content', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(
          message: _msg(
            sender: 'Anna Nowak',
            content: List.filled(1000, 'Long message line.').join(' '),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Anna Nowak'), findsOneWidget);

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -2000),
      );
      await tester.pump();

      expect(find.text('Anna Nowak').hitTestable(), findsNothing);
    });

    testWidgets('shows attachment count when files present', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          message: _msg(
            content: 'text',
            files: [
              const PocztaAttachment(name: 'doc.pdf', url: 'http://x'),
              const PocztaAttachment(name: 'img.jpg', url: 'http://y'),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('(2)'), findsOneWidget);
    });
    testWidgets('the scroll range never changes while reading a long message', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(454, 454);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final body = List.generate(
        90,
        (i) => 'Szanowni Panstwo, akapit numer $i tresci wiadomosci.',
      ).join(' ');

      await tester.pumpWidget(_buildScreen(message: _msg(content: body)));
      await tester.pump();
      await tester.pump();

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      final extentAtTop = position.maxScrollExtent;
      expect(extentAtTop, greaterThan(0));

      for (var offset = 0.0; offset < extentAtTop; offset += 100) {
        position.jumpTo(offset);
        await tester.pump();
        expect(
          position.maxScrollExtent,
          extentAtTop,
          reason:
              'a lazy list estimates its length from the children it has laid '
              'out, so one long paragraph among short ones makes the estimate '
              'lurch and the scroll indicator jump',
        );
      }
    });
  });
}
