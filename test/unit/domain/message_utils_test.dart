import 'package:bsharp/domain/message_utils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/real_bodies.dart';

void main() {
  group('formatMessageDate', () {
    test('shows time for today', () {
      final now = DateTime.now();
      final msg = DateTime(now.year, now.month, now.day, 14, 30);
      expect(formatMessageDate(msg), '14:30');
    });

    test('shows Yesterday for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final msg = DateTime(yesterday.year, yesterday.month, yesterday.day, 10);
      expect(formatMessageDate(msg), 'Yesterday');
    });

    test('shows day.month for same year', () {
      final now = DateTime.now();
      final msg = DateTime(now.year, 1, 5, 10);
      final today = DateTime(now.year, now.month, now.day);
      final msgDay = DateTime(now.year, 1, 5);
      final yesterday = today.subtract(const Duration(days: 1));

      if (msgDay != today && msgDay != yesterday) {
        expect(formatMessageDate(msg), '05.01');
      }
    });

    test('shows full date for different year', () {
      final msg = DateTime(2025, 6, 15, 10);
      expect(formatMessageDate(msg), '15.06.2025');
    });
  });

  group('formatMessageDateFull', () {
    test('includes date and time', () {
      final msg = DateTime(2026, 2, 27, 14, 30);
      expect(formatMessageDateFull(msg), '27.02.2026 14:30');
    });

    test('pads with leading zeros', () {
      final msg = DateTime(2026, 1, 5, 8, 5);
      expect(formatMessageDateFull(msg), '05.01.2026 08:05');
    });
  });

  group('messagePreview', () {
    test('strips HTML tags', () {
      expect(messagePreview('<p>Hello <b>world</b></p>'), 'Hello world');
    });

    test('collapses whitespace', () {
      expect(messagePreview('Hello   \n  world'), 'Hello world');
    });

    test('truncates long text', () {
      final long = 'a' * 200;
      final result = messagePreview(long, maxLength: 50);
      expect(result.length, 53);
      expect(result.endsWith('...'), isTrue);
    });

    test('returns short text as-is', () {
      expect(messagePreview('Short'), 'Short');
    });
  });

  group('stripHtml', () {
    test('the real announcement keeps one line per block', () {
      expect(
        stripHtml(realAnnouncementHtml),
        [
          ...realAnnouncementLines.sublist(0, 4),
          '• ${realAnnouncementLines[4]}',
          ...realAnnouncementLines.sublist(5),
        ].join('\n'),
      );
    });

    test('the library message keeps its paragraphs apart', () {
      final lines = stripHtml(libraryMessageHtml).split('\n');

      expect(lines.first, 'Szanowni Państwo!');
      expect(lines[1], contains('w związku z inwentaryzacją'));
      expect(lines.sublist(lines.length - 2), ['Z poważaniem', 'ZŁ']);
      expect(lines, hasLength(7));
    });

    test('decodes named and numeric entities', () {
      expect(
        stripHtml('Zesp&oacute;&#322; &#xF3;&amp;&lt;b&gt;&nbsp;x&quot;'),
        'Zespół ó&<b> x"',
      );
    });

    test('ends headings, divisions and table rows with a newline', () {
      expect(
        stripHtml(
          '<h1>Tytuł</h1><div>Treść</div>'
          '<table><tr><td>A</td><td>B</td></tr><tr><td>C</td></tr></table>',
        ),
        'Tytuł\nTreść\nA\nB\nC',
      );
    });

    test('numbers ordered items and bullets nested items', () {
      expect(
        stripHtml('<ol><li>Jeden<ul><li>Pod</li></ul></li><li>Dwa</li></ol>'),
        '1. Jeden\n• Pod\n2. Dwa',
      );
    });

    test('keeps at most one blank line in a row', () {
      expect(stripHtml('<p>a<br><br><br><br>b</p>'), 'a\n\nb');
    });

    test('drops scripts and styles', () {
      expect(
        stripHtml('<style>p{}</style><p>Tekst</p><script>x()</script>'),
        'Tekst',
      );
    });
  });

  group('messagePreview of real bodies', () {
    test('decodes the library list preview into one spaced line', () {
      final preview = messagePreview(realLibraryPreview, maxLength: 1000);

      expect(preview, isNot(contains('&')));
      expect(preview, contains('w związku z inwentaryzacją'));
      expect(preview, endsWith('inwentaryzacji. Z poważaniemZŁ'));
    });

    test('separates the blocks of the real announcement', () {
      final preview = messagePreview(realAnnouncementHtml, maxLength: 1000);

      expect(preview, startsWith('Szanowni Państwo, pragniemy poinformować'));
      expect(preview, contains('instrukcji: Rodzic/Uczeń'));
      expect(preview, endsWith('Z wyrazami szacunku, Zespół MobiReg'));
    });
  });
}
