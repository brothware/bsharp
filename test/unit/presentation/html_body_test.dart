import 'package:bsharp/presentation/common/widgets/html_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/real_bodies.dart';
import 'link_tap.dart';

Widget _app(String html, Future<bool> Function(Uri) launcher) {
  return ProviderScope(
    overrides: [linkLauncherProvider.overrideWithValue(launcher)],
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: HtmlBody(html))),
    ),
  );
}

Future<bool> _neverOpens(Uri uri) async => false;

void main() {
  testWidgets('renders the real announcement without markup', (tester) async {
    await tester.pumpWidget(_app(realAnnouncementHtml, _neverOpens));
    await tester.pumpAndSettle();

    expect(find.textContaining('<', findRichText: true), findsNothing);
    expect(find.textContaining('&', findRichText: true), findsNothing);
    expect(
      find.textContaining('Zespół MobiReg', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Życzymy przyjemnego', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('keeps the text selectable', (tester) async {
    await tester.pumpWidget(_app(realAnnouncementHtml, _neverOpens));
    await tester.pumpAndSettle();

    expect(find.byType(SelectionArea), findsOneWidget);
  });

  testWidgets('a link tap opens the link', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      _app(realAnnouncementHtml, (uri) async {
        opened.add(uri);
        return true;
      }),
    );
    await tester.pumpAndSettle();

    await tapLinkText(tester, 'Rodzic/Uczeń');

    expect(opened, [Uri.parse(realAnnouncementLink)]);
    expect(find.text('Could not open the link'), findsNothing);
  });

  testWidgets('a link that cannot be opened shows an error', (tester) async {
    await tester.pumpWidget(_app(realAnnouncementHtml, _neverOpens));
    await tester.pumpAndSettle();

    await tapLinkText(tester, 'Rodzic/Uczeń');

    expect(find.text('Could not open the link'), findsOneWidget);
  });

  testWidgets('a launcher that throws shows an error', (tester) async {
    await tester.pumpWidget(
      _app(
        realAnnouncementHtml,
        (uri) async => throw PlatformException(code: 'ACTIVITY_NOT_FOUND'),
      ),
    );
    await tester.pumpAndSettle();

    await tapLinkText(tester, 'Rodzic/Uczeń');

    expect(find.text('Could not open the link'), findsOneWidget);
  });

  testWidgets('any launcher failure shows an error', (tester) async {
    await tester.pumpWidget(
      _app(
        realAnnouncementHtml,
        (uri) async => throw ArgumentError.value(uri, 'uri', 'no handler'),
      ),
    );
    await tester.pumpAndSettle();

    await tapLinkText(tester, 'Rodzic/Uczeń');

    expect(find.text('Could not open the link'), findsOneWidget);
  });
}
