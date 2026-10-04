import 'package:bsharp/domain/html_blocks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/real_bodies.dart';

void main() {
  group('parseHtmlBlocks', () {
    test('splits the real announcement into its blocks and lines', () {
      final blocks = parseHtmlBlocks(realAnnouncementHtml);

      expect(blocks, hasLength(8));
      expect(
        [
          for (final block in blocks)
            for (final line in block.lines) line.text,
        ],
        realAnnouncementLines,
      );
      expect(blocks.last.lines, hasLength(2));
    });

    test('the real list item is a whole-block link', () {
      final item = parseHtmlBlocks(realAnnouncementHtml)[4];

      expect(item.kind, isA<ListItemKind>());
      expect((item.kind as ListItemKind).list.isOrdered, isFalse);
      expect(item.lines.single.link, realAnnouncementLink);
      expect(item.lines.single.links, isEmpty);
    });

    test('records a style only when it covers the whole line', () {
      final blocks = parseHtmlBlocks(
        '<p><b>Uwaga: <i>jutro</i> krócej.</b></p><p>Jest <b>ważne</b>.</p>',
      );

      expect(blocks[0].lines.single.styles, {HtmlTextStyle.bold});
      expect(blocks[1].lines.single.styles, isEmpty);
    });

    test('lists links inside a sentence', () {
      final line = parseHtmlBlocks(
        '<p>Instrukcja jest <a href="https://a.pl">na stronie</a> pomocy.</p>',
      ).single.lines.single;

      expect(line.link, isNull);
      expect(line.links, ['https://a.pl']);
      expect(line.text, 'Instrukcja jest na stronie pomocy.');
    });

    test('numbers ordered items from the list start', () {
      final blocks = parseHtmlBlocks(
        '<ol start="3"><li>Trzy</li><li>Cztery</li></ol>',
      );

      expect(
        [
          for (final block in blocks) (block.kind as ListItemKind).index,
        ],
        [3, 4],
      );
    });

    test('honours an item value and continues from it', () {
      final blocks = parseHtmlBlocks(
        '<ol><li value="5">Pięć</li><li>Sześć</li></ol>',
      );

      expect(
        [
          for (final block in blocks) (block.kind as ListItemKind).index,
        ],
        [5, 6],
      );
    });

    test('keeps nested lists inside their parent list', () {
      final blocks = parseHtmlBlocks(
        '<ul><li>A<ol><li>A1</li></ol></li><li>B</li></ul>',
      );
      final kinds = blocks.map((block) => block.kind as ListItemKind).toList();

      expect(kinds.map((kind) => kind.lists.length), [1, 2, 1]);
      expect(kinds[1].lists.first.id, kinds[0].list.id);
      expect(kinds[2].list.id, kinds[0].list.id);
    });

    test('paragraphs inside a list item stay lines of that item', () {
      final blocks = parseHtmlBlocks('<ul><li><p>A</p><p>B</p></li></ul>');

      expect(blocks.single.lines.map((line) => line.text), ['A', 'B']);
    });

    test('records headings and table cells', () {
      final blocks = parseHtmlBlocks(
        '<h2>Plan</h2><table><tr><th>Dzień</th><td>Pon</td></tr></table>',
      );

      expect((blocks[0].kind as HeadingKind).level, 2);
      expect((blocks[1].kind as CellKind).isHeader, isTrue);
      expect(
        (blocks[2].kind as CellKind).row,
        (blocks[1].kind as CellKind).row,
      );
    });

    test('drops empty paragraphs', () {
      expect(parseHtmlBlocks('<p>&nbsp;</p><p> </p>'), isEmpty);
    });
  });

  group('translationUnits', () {
    test('are the plain non-blank lines in order', () {
      expect(
        translationUnits(parseHtmlBlocks(realAnnouncementHtml)),
        realAnnouncementLines,
      );
    });

    test('skip blank lines between line breaks', () {
      expect(translationUnits(parseHtmlBlocks('<p>a<br><br>b</p>')), [
        'a',
        'b',
      ]);
    });
  });

  group('rebuildTranslatedHtml', () {
    String rebuild(String html, List<String> pieces) {
      return rebuildTranslatedHtml(parseHtmlBlocks(html), pieces.join('\n'));
    }

    test('keeps the real announcement structure', () {
      final pieces = [
        for (var i = 0; i < realAnnouncementLines.length; i++) 'T$i',
      ];
      final rebuilt = parseHtmlBlocks(
        rebuild(realAnnouncementHtml, pieces),
      );
      final original = parseHtmlBlocks(realAnnouncementHtml);

      expect(translationUnits(rebuilt), pieces);
      expect(
        rebuilt.map((block) => block.kind.runtimeType),
        original.map((block) => block.kind.runtimeType),
      );
      expect(rebuilt.last.lines.map((line) => line.text), ['T7', 'T8']);
    });

    test('a whole-block link stays a link', () {
      final pieces = [
        for (var i = 0; i < realAnnouncementLines.length; i++) 'T$i',
      ];
      final item = parseHtmlBlocks(rebuild(realAnnouncementHtml, pieces))[4];

      expect(item.kind, isA<ListItemKind>());
      expect(item.lines.single.text, 'T4');
      expect(item.lines.single.link, realAnnouncementLink);
    });

    test('re-applies whole-block styling only', () {
      final blocks = parseHtmlBlocks(
        rebuild('<p><strong>Uwaga!</strong></p><p>Jest <b>ważne</b>.</p>', [
          'Note!',
          'It is important.',
        ]),
      );

      expect(blocks[0].lines.single.styles, {HtmlTextStyle.bold});
      expect(blocks[1].lines.single.styles, isEmpty);
      expect(blocks[1].lines.single.text, 'It is important.');
    });

    test('lists a mid-sentence link under its translated block', () {
      final block = parseHtmlBlocks(
        rebuild(
          '<p>Instrukcja jest <a href="https://a.pl/x?a=1&amp;b=2">tutaj</a>, '
          'a pytania do sekretariatu.</p><p>Dalej</p>',
          ['The manual is here, and questions to the office.', 'Next'],
        ),
      ).first;

      expect(block.lines.map((line) => line.text), [
        'The manual is here, and questions to the office.',
        'https://a.pl/x?a=1&b=2',
      ]);
      expect(block.lines.last.link, 'https://a.pl/x?a=1&b=2');
    });

    test('keeps list numbering and nesting', () {
      final blocks = parseHtmlBlocks(
        rebuild(
          '<ol start="3"><li>Trzy<ul><li>Pod</li></ul></li><li>Cztery</li></ol>',
          ['Three', 'Sub', 'Four'],
        ),
      );
      final kinds = blocks.map((block) => block.kind as ListItemKind).toList();

      expect(kinds.map((kind) => kind.index), [3, 1, 4]);
      expect(kinds.map((kind) => kind.list.isOrdered), [true, false, true]);
      expect(kinds.map((kind) => kind.lists.length), [1, 2, 1]);
    });

    test('keeps numbers after an empty list item', () {
      final blocks = parseHtmlBlocks(
        rebuild('<ol><li>A</li><li></li><li>C</li></ol>', ['A', 'C']),
      );

      expect(
        [
          for (final block in blocks) (block.kind as ListItemKind).index,
        ],
        [1, 3],
      );
      expect(
        rebuild('<ol><li>A</li><li></li><li>C</li></ol>', ['A', 'C']),
        contains('<ol start="3"><li>C'),
      );
    });

    test('keeps numbers after text that follows a nested list', () {
      final blocks = parseHtmlBlocks(
        rebuild(
          '<ol><li>A<ul><li>a1</li></ul>dalej</li><li>B</li><li>C</li></ol>',
          ['A', 'a1', 'more', 'B', 'C'],
        ),
      );
      final ordered = blocks
          .map((block) => block.kind as ListItemKind)
          .where((kind) => kind.list.isOrdered);

      expect(ordered.map((kind) => kind.index), [1, 1, 2, 3]);
      expect(
        rebuild(
          '<ol><li>A<ul><li>a1</li></ul>dalej</li><li>B</li></ol>',
          ['A', 'a1', 'more', 'B'],
        ),
        contains('</ul><br>more</li><li>B'),
      );
    });

    test('keeps headings and tables', () {
      final blocks = parseHtmlBlocks(
        rebuild(
          '<h2>Plan</h2><table><tr><th>Dzień</th><td>Pon</td></tr>'
          '<tr><td>Wt</td></tr></table>',
          ['Plan', 'Day', 'Mon', 'Tue'],
        ),
      );

      expect((blocks[0].kind as HeadingKind).level, 2);
      final cells = blocks.skip(1).map((block) => block.kind as CellKind);
      expect(cells.map((cell) => cell.isHeader), [true, false, false]);
      expect(cells.elementAt(0).row, cells.elementAt(1).row);
      expect(cells.elementAt(2).row, isNot(cells.elementAt(1).row));
    });

    test('escapes the translated text', () {
      final line = parseHtmlBlocks(
        rebuild('<p>a</p>', ['<b>x</b> & y']),
      ).single.lines.single;

      expect(line.text, '<b>x</b> & y');
      expect(line.styles, isEmpty);
    });

    test('a piece count mismatch falls back to plain lines', () {
      final rebuilt = rebuild(realAnnouncementHtml, ['One', 'Two']);

      expect(stripHtmlLines(rebuilt), ['One', 'Two']);
      expect(parseHtmlBlocks(rebuilt).single.kind, isA<ParagraphKind>());
    });
  });
}

List<String> stripHtmlLines(String html) {
  return htmlBlocksToPlainText(parseHtmlBlocks(html)).split('\n');
}
