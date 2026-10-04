import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/presentation/messages/screens/messages_screen.dart';
import 'package:bsharp/presentation/messages/widgets/compose_message_view.dart';
import 'package:bsharp/presentation/messages/widgets/message_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _rejected = MessagingException(SessionExpired());

class _RejectingMailProvider extends DemoDataProvider {
  @override
  Future<void> toggleStar(int messageId) async => throw _rejected;

  @override
  Future<List<PocztaMessage>> loadMoreInbox(int skip) async => throw _rejected;

  @override
  Future<Map<String, dynamic>?> readMessage(int messageId) async =>
      throw _rejected;

  @override
  Future<List<PocztaReceiver>> searchReceivers(String query) async =>
      throw _rejected;

  @override
  Future<String?> downloadAttachment(String url, String filename) async =>
      throw _rejected;
}

class _ReadableRejectingMailProvider extends _RejectingMailProvider {
  @override
  Future<Map<String, dynamic>?> readMessage(int messageId) async => null;
}

PocztaMessage _message({int id = 1, List<PocztaAttachment>? files}) {
  return PocztaMessage(
    id: id,
    title: 'Zebranie',
    senderName: 'Anna Nowak',
    sendTime: DateTime(2026, 10),
    isRead: true,
    isStarred: false,
    files: files,
  );
}

late SharedPreferences _prefs;

Widget _app(Widget home, {SchoolDataProvider? provider}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_prefs),
      inboxProvider.overrideWithBuild((ref, _) => [_message()]),
      sentProvider.overrideWithBuild((ref, _) => const []),
      trashProvider.overrideWithBuild((ref, _) => const []),
      activeDataProviderProvider.overrideWithBuild(
        (ref, _) => provider ?? _RejectingMailProvider(),
      ),
    ],
    child: MaterialApp(home: home),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  testWidgets('a rejected star shows an error', (tester) async {
    await tester.pumpWidget(_app(const Scaffold(body: MessagesScreen())));

    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pumpAndSettle();

    expect(find.text('Could not update the message'), findsOneWidget);
  });

  testWidgets('a rejected page of older mail shows an error', (tester) async {
    await tester.pumpWidget(_app(const Scaffold(body: MessagesScreen())));

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Could not load more messages'), findsOneWidget);
  });

  testWidgets('a message that cannot be read shows an error', (tester) async {
    await tester.pumpWidget(_app(MessageDetailView(message: _message())));
    await tester.pumpAndSettle();

    expect(find.text('Could not load the message'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a rejected download shows an error', (tester) async {
    await tester.pumpWidget(
      _app(
        MessageDetailView(
          message: _message(
            id: 2,
            files: const [PocztaAttachment(name: 'a.pdf', url: '/files/1')],
          ),
        ),
        provider: _ReadableRejectingMailProvider(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('a.pdf'));
    await tester.pumpAndSettle();

    expect(find.text('Download failed'), findsOneWidget);
  });

  testWidgets('a failed receiver search shows an error', (tester) async {
    await tester.pumpWidget(_app(const Scaffold(body: ComposeMessageView())));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Nowak');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Could not search for recipients'), findsOneWidget);
  });
}
