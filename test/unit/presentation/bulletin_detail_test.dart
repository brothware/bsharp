import 'package:bsharp/app/providers/more_providers.dart';
import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/local/mlkit_translation_source.dart';
import 'package:bsharp/data/services/translation_service.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/bulletins/screens/bulletins_screen.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fixtures/real_bodies.dart';

const _title = 'Nowa aplikacja na urządzenia mobilne';

late SharedPreferences _prefs;

Widget _app({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_prefs),
      bulletinsProvider.overrideWithBuild(
        (ref, _) => [
          PortalBulletin(
            id: 12,
            title: _title,
            content: realAnnouncementHtml,
            date: DateTime(2025, 9, 30, 15, 9),
            author: 'mobireg',
            isRead: true,
          ),
        ],
      ),
      ...overrides,
    ],
    child: const MaterialApp(home: Scaffold(body: BulletinsScreen())),
  );
}

Future<void> _openDetail(WidgetTester tester) async {
  await tester.tap(find.text(_title));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  testWidgets('the list says yesterday in the app language', (tester) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.pl));
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bulletinsProvider.overrideWithBuild(
            (ref, _) => [
              PortalBulletin(
                id: 1,
                title: _title,
                content: '',
                date: DateTime(yesterday.year, yesterday.month, yesterday.day),
                author: 'mobireg',
                isRead: true,
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: BulletinsScreen())),
      ),
    );

    expect(find.text('mobireg • Wczoraj'), findsOneWidget);
  });

  testWidgets('the detail renders the real body formatted', (tester) async {
    await tester.pumpWidget(_app());
    await _openDetail(tester);

    expect(find.text('30.09.2025 15:09'), findsOneWidget);
    expect(find.textContaining('<p>', findRichText: true), findsNothing);
    expect(find.textContaining('&oacute;', findRichText: true), findsNothing);
    expect(
      find.textContaining('Zespół MobiReg', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('translates the title and keeps the body structure', (
    tester,
  ) async {
    final mlKit = _NumberingMlKit();
    await tester.pumpWidget(
      _app(
        overrides: [
          isTranslationAvailableProvider.overrideWithValue(true),
          translationServiceProvider.overrideWithValue(
            TranslationService(mlKit: mlKit),
          ),
        ],
      ),
    );
    await _openDetail(tester);

    await tester.tap(find.byIcon(Icons.translate));
    await tester.pumpAndSettle();

    expect(mlKit.sent, contains(_title));
    expect(mlKit.sent.where((text) => text.contains('<')), isEmpty);
    expect(find.text('T0'), findsOneWidget);
    expect(find.textContaining('Zespół', findRichText: true), findsNothing);
    expect(find.textContaining('T8', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Show original'));
    await tester.pumpAndSettle();

    expect(find.text(_title), findsOneWidget);
    expect(
      find.textContaining('Zespół MobiReg', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('hides translation when the app speaks the content language', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        overrides: [isTranslationAvailableProvider.overrideWithValue(false)],
      ),
    );
    await _openDetail(tester);

    expect(find.byIcon(Icons.translate), findsNothing);
  });
}

class _NumberingMlKit extends MlKitTranslationSource {
  final sent = <String>[];

  @override
  Future<Result<String>> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    sent.add(text);
    final pieces = text.split(' ‣ ');
    return Result.success(
      [for (var i = 0; i < pieces.length; i++) 'T$i'].join(' ‣ '),
    );
  }
}
