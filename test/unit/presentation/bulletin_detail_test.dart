import 'package:bsharp/app/providers/more_providers.dart';
import 'package:bsharp/domain/entities/portal.dart';
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
}
