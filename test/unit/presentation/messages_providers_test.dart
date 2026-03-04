import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/presentation/messages/providers/messages_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PocztaMessage msg({int id = 1, bool isRead = false, bool isStarred = false}) {
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
          inboxProvider.overrideWithBuild(
            (ref, _) => [msg(), msg(id: 2, isRead: true), msg(id: 3)],
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(unreadCountProvider), 2);
    });

    test('returns 0 when all read', () {
      final container = ProviderContainer(
        overrides: [
          inboxProvider.overrideWithBuild(
            (ref, _) => [msg(isRead: true), msg(id: 2, isRead: true)],
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(unreadCountProvider), 0);
    });

    test('returns 0 when empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(unreadCountProvider), 0);
    });
  });

  group('starredMessagesProvider', () {
    test('filters starred messages', () {
      final container = ProviderContainer(
        overrides: [
          inboxProvider.overrideWithBuild(
            (ref, _) => [
              msg(isStarred: true),
              msg(id: 2),
              msg(id: 3, isStarred: true),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final starred = container.read(starredMessagesProvider);
      expect(starred.length, 2);
      expect(starred.every((m) => m.isStarred), isTrue);
    });
  });

  group('currentFolderMessagesProvider', () {
    test('returns inbox when inbox selected', () {
      final container = ProviderContainer(
        overrides: [
          inboxProvider.overrideWithBuild((ref, _) => [msg(), msg(id: 2)]),
          sentProvider.overrideWithBuild((ref, _) => [msg(id: 3)]),
        ],
      );
      addTearDown(container.dispose);

      final messages = container.read(currentFolderMessagesProvider);
      expect(messages.length, 2);
    });

    test('returns sent when sent selected', () {
      final container = ProviderContainer(
        overrides: [
          selectedFolderProvider.overrideWithBuild(
            (ref, _) => MessageFolder.sent,
          ),
          inboxProvider.overrideWithBuild((ref, _) => [msg()]),
          sentProvider.overrideWithBuild((ref, _) => [msg(id: 2), msg(id: 3)]),
        ],
      );
      addTearDown(container.dispose);

      final messages = container.read(currentFolderMessagesProvider);
      expect(messages.length, 2);
    });

    test('returns trash when trash selected', () {
      final container = ProviderContainer(
        overrides: [
          selectedFolderProvider.overrideWithBuild(
            (ref, _) => MessageFolder.trash,
          ),
          trashProvider.overrideWithBuild((ref, _) => [msg(id: 4)]),
        ],
      );
      addTearDown(container.dispose);

      final messages = container.read(currentFolderMessagesProvider);
      expect(messages.length, 1);
    });
  });
}
