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
}
