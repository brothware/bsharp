import 'package:bsharp/data/providers/mobireg/mobireg_message_handler.dart';
import 'package:flutter_test/flutter_test.dart';

const _folder = 'inbox';
const _messageId = 7;

Map<String, dynamic> _message({Object? id = _messageId, Object? date}) {
  return {
    'id': id,
    'subject': 'Wycieczka',
    'author': {'name': 'Agnieszka Nowak'},
    'date': date ?? '2026-10-01T12:30:00Z',
    'content': 'Szczegóły w załączniku',
    'stared': true,
    'recipients': [
      {'name': 'Jan Kowalski', 'roleName': 'rodzic', 'read_at': null},
    ],
  };
}

void main() {
  group('parsePocztaMessages', () {
    test('parses a well-formed list', () {
      final messages = parsePocztaMessages([_message()], _folder);

      expect(messages.single.id, _messageId);
      expect(messages.single.title, 'Wycieczka');
      expect(messages.single.senderName, 'Agnieszka Nowak');
      expect(messages.single.isStarred, isTrue);
      expect(messages.single.isRead, isFalse);
      expect(messages.single.recipients.single.role, 'rodzic');
    });

    test('keeps optional fields optional', () {
      final messages = parsePocztaMessages([
        {'id': 1, 'date': '2026-10-01T12:30:00Z'},
      ], _folder);

      expect(messages.single.title, '');
      expect(messages.single.senderName, '');
      expect(messages.single.recipients, isEmpty);
    });

    test('an item that is not an object is a FormatException', () {
      expect(
        () => parsePocztaMessages(['x'], _folder),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('poczta inbox'),
          ),
        ),
      );
    });

    test('a missing id is a FormatException', () {
      expect(
        () => parsePocztaMessages([_message(id: null)], _folder),
        throwsFormatException,
      );
    });

    test('a failure does not carry the mail content', () {
      expect(
        () => parsePocztaMessages([_message(id: null)], _folder),
        throwsA(
          isA<FormatException>().having(
            (e) => '${e.source}',
            'source',
            isNot(contains('Szczegóły')),
          ),
        ),
      );
    });

    test('an unreadable date is a FormatException', () {
      expect(
        () => parsePocztaMessages([_message(date: 'jutro')], _folder),
        throwsFormatException,
      );
    });
  });
}
