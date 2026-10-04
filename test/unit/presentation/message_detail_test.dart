import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/presentation/common/widgets/html_body.dart';
import 'package:bsharp/presentation/messages/widgets/message_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fixtures/real_bodies.dart';

class _BodyProvider extends DemoDataProvider {
  _BodyProvider(this.body);

  final String body;

  @override
  Future<Map<String, dynamic>?> readMessage(int messageId) async => {
    'content': body,
  };
}

class _FlakyProvider extends DemoDataProvider {
  int reads = 0;

  @override
  Future<Map<String, dynamic>?> readMessage(int messageId) async {
    reads++;
    if (reads == 1) {
      throw const MessagingException(ConnectionTimeout());
    }
    return {'content': libraryMessageHtml};
  }
}

final _message = PocztaMessage(
  id: 7,
  title: 'Inwentaryzacja biblioteki',
  senderName: 'Biblioteka',
  sendTime: DateTime(2026, 9, 16, 16, 8),
  isRead: true,
  isStarred: false,
  preview: realLibraryPreview,
  content: realLibraryPreview,
);

late SharedPreferences _prefs;

Widget _app(
  SchoolDataProvider provider, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_prefs),
      inboxProvider.overrideWithBuild((ref, _) => [_message]),
      sentProvider.overrideWithBuild((ref, _) => const []),
      trashProvider.overrideWithBuild((ref, _) => const []),
      activeDataProviderProvider.overrideWithBuild((ref, _) => provider),
      ...overrides,
    ],
    child: MaterialApp(home: MessageDetailView(message: _message)),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  testWidgets('renders the full message body as HTML', (tester) async {
    await tester.pumpWidget(_app(_BodyProvider(libraryMessageHtml)));
    await tester.pumpAndSettle();

    expect(find.textContaining('<p>', findRichText: true), findsNothing);
    expect(find.textContaining('&nbsp;', findRichText: true), findsNothing);
    expect(
      find.textContaining('Szanowni Państwo!', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Prosimy o współpracę.', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('a failed read shows an error with retry, never the preview', (
    tester,
  ) async {
    final provider = _FlakyProvider();
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    expect(find.text('Could not load the message'), findsOneWidget);
    expect(find.textContaining('Szanowni', findRichText: true), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(provider.reads, 2);
    expect(find.text('Could not load the message'), findsNothing);
    expect(
      find.textContaining('Szanowni Państwo!', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('decodes every entity and keeps links tappable', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_BodyProvider(realAnnouncementHtml)));
    await tester.pumpAndSettle();

    expect(find.byType(HtmlBody), findsOneWidget);
    expect(find.textContaining('&oacute;', findRichText: true), findsNothing);
    expect(
      find.textContaining('Zespół MobiReg', findRichText: true),
      findsOneWidget,
    );
  });
}
