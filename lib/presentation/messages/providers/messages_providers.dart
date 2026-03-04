import 'package:bsharp/domain/entities/poczta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final inboxProvider = StateProvider<List<PocztaMessage>>((ref) => []);

final inboxHasMoreProvider = StateProvider<bool>((ref) => true);

final sentProvider = StateProvider<List<PocztaMessage>>((ref) => []);

final trashProvider = StateProvider<List<PocztaMessage>>((ref) => []);

final receiversProvider = StateProvider<List<PocztaReceiver>>((ref) => []);

final unreadCountProvider = Provider<int>((ref) {
  final inbox = ref.watch(inboxProvider);
  return inbox.where((m) => !m.isRead).length;
});

final starredMessagesProvider = Provider<List<PocztaMessage>>((ref) {
  final inbox = ref.watch(inboxProvider);
  return inbox.where((m) => m.isStarred).toList();
});

enum MessageFolder { inbox, sent, trash }

final selectedFolderProvider = StateProvider<MessageFolder>(
  (ref) => MessageFolder.inbox,
);

final currentFolderMessagesProvider = Provider<List<PocztaMessage>>((ref) {
  final folder = ref.watch(selectedFolderProvider);
  return switch (folder) {
    MessageFolder.inbox => ref.watch(inboxProvider),
    MessageFolder.sent => ref.watch(sentProvider),
    MessageFolder.trash => ref.watch(trashProvider),
  };
});
