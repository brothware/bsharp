import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/presentation/messages/providers/messages_providers.dart';

void main() {
  PocztaMessage _msg({
    int id = 1,
    bool isRead = false,
    bool isStarred = false,
  }) {
    return PocztaMessage(
      id: id,
      title: 'Test',
      senderName: 'Jan Kowalski',
      sendTime: DateTime(2026, 2, 27),
      isRead: isRead,
      isStarred: isStarred,
    );
  }

  group('unreadCountProvider', () {
    test('counts unread messages', () {
      final container = ProviderContainer(
        overrides: [
          inboxProvider.overrideWith(
            (ref) => [
              _msg(id: 1, isRead: false),
              _msg(id: 2, isRead: true),
              _msg(id: 3, isRead: false),
            ],
          ),
        ],
      );

      expect(container.read(unreadCountProvider), 2);
    });

    test('returns 0 when all read', () {
      final container = ProviderContainer(
        overrides: [
          inboxProvider.overrideWith(
            (ref) => [
              _msg(id: 1, isRead: true),
              _msg(id: 2, isRead: true),
            ],
          ),
        ],
      );

      expect(container.read(unreadCountProvider), 0);
    });

    test('returns 0 when empty', () {
      final container = ProviderContainer();
      expect(container.read(unreadCountProvider), 0);
    });
  });

  group('starredMessagesProvider', () {
    test('filters starred messages', () {
      final container = ProviderContainer(
        overrides: [
          inboxProvider.overrideWith(
            (ref) => [
              _msg(id: 1, isStarred: true),
              _msg(id: 2, isStarred: false),
              _msg(id: 3, isStarred: true),
            ],
          ),
        ],
      );

      final starred = container.read(starredMessagesProvider);
      expect(starred.length, 2);
      expect(starred.every((m) => m.isStarred), isTrue);
    });
  });

  group('currentFolderMessagesProvider', () {
    test('returns inbox when inbox selected', () {
      final container = ProviderContainer(
        overrides: [
          inboxProvider.overrideWith(
            (ref) => [_msg(id: 1), _msg(id: 2)],
          ),
          sentProvider.overrideWith(
            (ref) => [_msg(id: 3)],
          ),
        ],
      );

      final messages = container.read(currentFolderMessagesProvider);
      expect(messages.length, 2);
    });

    test('returns sent when sent selected', () {
      final container = ProviderContainer(
        overrides: [
          selectedFolderProvider.overrideWith(
            (ref) => MessageFolder.sent,
          ),
          inboxProvider.overrideWith(
            (ref) => [_msg(id: 1)],
          ),
          sentProvider.overrideWith(
            (ref) => [_msg(id: 2), _msg(id: 3)],
          ),
        ],
      );

      final messages = container.read(currentFolderMessagesProvider);
      expect(messages.length, 2);
    });

    test('returns trash when trash selected', () {
      final container = ProviderContainer(
        overrides: [
          selectedFolderProvider.overrideWith(
            (ref) => MessageFolder.trash,
          ),
          trashProvider.overrideWith(
            (ref) => [_msg(id: 4)],
          ),
        ],
      );

      final messages = container.read(currentFolderMessagesProvider);
      expect(messages.length, 1);
    });
  });
}
