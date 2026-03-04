import 'package:bsharp/domain/message_utils.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
