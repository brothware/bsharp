import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/local/database.dart';
import 'package:bsharp/data/data_sources/local/mlkit_translation_source.dart';
import 'package:bsharp/data/data_sources/remote/deepl_data_source.dart';
import 'package:bsharp/data/services/translation_service.dart';
import 'package:bsharp/domain/html_blocks.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/real_bodies.dart';

const _marker = '‣';
final _entity = RegExp('&(#x?[0-9a-fA-F]+|[a-zA-Z]+);');

class _FakeMlKit extends MlKitTranslationSource {
  _FakeMlKit(this._translate);

  final String Function(String) _translate;
  final sent = <String>[];

  @override
  Future<Result<String>> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    sent.add(text);
    return Result.success(_translate(text));
  }
}

class _FakeDeepL extends DeepLDataSource {
  _FakeDeepL() : super(apiKey: 'test');

  final sent = <({String text, bool isHtml})>[];

  @override
  Future<Result<List<String>>> translate({
    required List<String> texts,
    required String targetLang,
    String sourceLang = 'PL',
    bool isHtml = false,
  }) async {
    sent.add((text: texts.single, isHtml: isHtml));
    return const Result.success(['<p><b>Dear all</b></p>']);
  }
}

String _numberPieces(String text) {
  final pieces = text.split(' $_marker ');
  return [for (var i = 0; i < pieces.length; i++) 'T$i'].join(' $_marker ');
}

Future<String> _translateHtml(TranslationService service, String html) async {
  final result = await service.translate(
    text: html,
    targetLang: 'en',
    sourceLang: 'pl',
    isHtml: true,
  );
  return result.when(
    success: (value) => value,
    failure: (failure) => fail('translation failed: $failure'),
  );
}

void main() {
  group('ML Kit with an HTML body', () {
    test('sends plain blocks joined by the marker, nothing else', () async {
      final mlKit = _FakeMlKit(_numberPieces);
      final service = TranslationService(mlKit: mlKit);

      await _translateHtml(service, realAnnouncementHtml);

      final sent = mlKit.sent.single;
      expect(sent, isNot(contains('<')));
      expect(sent, isNot(contains('>')));
      expect(_entity.hasMatch(sent), isFalse);
      expect(
        _marker.allMatches(sent),
        hasLength(realAnnouncementLines.length - 1),
      );
      expect(sent.split(' $_marker '), realAnnouncementLines);
    });

    test('rebuilds the structure from the translated pieces', () async {
      final service = TranslationService(mlKit: _FakeMlKit(_numberPieces));

      final translated = parseHtmlBlocks(
        await _translateHtml(service, realAnnouncementHtml),
      );

      expect(translated, hasLength(8));
      expect(translated[4].kind, isA<ListItemKind>());
      expect(translated[4].lines.single.link, realAnnouncementLink);
      expect(translated.last.lines.map((line) => line.text), ['T7', 'T8']);
    });

    test('a dropped marker falls back to plain lines', () async {
      final service = TranslationService(
        mlKit: _FakeMlKit((text) => 'One $_marker Two'),
      );

      final translated = await _translateHtml(service, realAnnouncementHtml);

      expect(htmlBlocksToPlainText(parseHtmlBlocks(translated)), 'One\nTwo');
    });

    test('caches on the text sent to ML Kit', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final mlKit = _FakeMlKit(_numberPieces);
      final service = TranslationService(database: database, mlKit: mlKit);

      final first = await _translateHtml(service, libraryMessageHtml);
      final second = await _translateHtml(service, libraryMessageHtml);

      expect(mlKit.sent, hasLength(1));
      expect(second, first);
    });

    test('plain text keeps the newline marker path', () async {
      final mlKit = _FakeMlKit((text) => text.toUpperCase());
      final service = TranslationService(mlKit: mlKit);

      final result = await service.translate(
        text: 'a\nb',
        targetLang: 'en',
        sourceLang: 'pl',
      );

      expect(mlKit.sent.single, 'a $_marker b');
      expect(result, isA<Success<String>>());
      expect((result as Success<String>).value, 'A\nB');
    });
  });

  test('DeepL gets the original HTML and returns HTML', () async {
    final deepL = _FakeDeepL();
    final service = TranslationService(deepL: deepL);

    final translated = await _translateHtml(service, realAnnouncementHtml);

    expect(deepL.sent.single, (text: realAnnouncementHtml, isHtml: true));
    expect(translated, '<p><b>Dear all</b></p>');
  });
}
