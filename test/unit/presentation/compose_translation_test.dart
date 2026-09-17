import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/data/services/translation_service.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/presentation/messages/widgets/compose_message_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingTranslationService extends TranslationService {
  String? targetLang;
  String? sourceLang;

  @override
  bool get isAvailable => true;

  @override
  Future<Result<String>> translate({
    required String text,
    required String targetLang,
    required String sourceLang,
    bool isHtml = false,
  }) async {
    this.targetLang = targetLang;
    this.sourceLang = sourceLang;
    return const Result.success('translated');
  }
}

void main() {
  testWidgets('composing translates into the language the provider reads', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'locale': 'pl'});
    final prefs = await SharedPreferences.getInstance();
    final service = _RecordingTranslationService();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        translationServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);
    container.read(activeDataProviderProvider.notifier).value =
        DemoDataProvider();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: ComposeMessageView()),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).last, 'Dzień dobry');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.translate));
    await tester.pumpAndSettle();

    expect(service.targetLang, 'en', reason: 'demo provider reads English');
    expect(service.sourceLang, 'pl', reason: 'the app is in Polish');
  });
}
