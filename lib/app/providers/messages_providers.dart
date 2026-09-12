import 'package:bsharp/domain/entities/poczta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'messages_providers.g.dart';

@Riverpod(keepAlive: true)
class Inbox extends _$Inbox {
  @override
  List<PocztaMessage> build() => [];
  List<PocztaMessage> get value => state;
  set value(List<PocztaMessage> v) => state = v;
}

@Riverpod(keepAlive: true)
class InboxHasMore extends _$InboxHasMore {
  @override
  bool build() => true;
  bool get value => state;
  set value(bool v) => state = v;
}

@Riverpod(keepAlive: true)
class Sent extends _$Sent {
  @override
  List<PocztaMessage> build() => [];
  List<PocztaMessage> get value => state;
  set value(List<PocztaMessage> v) => state = v;
}

@Riverpod(keepAlive: true)
class Trash extends _$Trash {
  @override
  List<PocztaMessage> build() => [];
  List<PocztaMessage> get value => state;
  set value(List<PocztaMessage> v) => state = v;
}

@Riverpod(keepAlive: true)
class Receivers extends _$Receivers {
  @override
  List<PocztaReceiver> build() => [];
  List<PocztaReceiver> get value => state;
  set value(List<PocztaReceiver> v) => state = v;
}

@Riverpod(keepAlive: true)
int unreadCount(Ref ref) {
  final inbox = ref.watch(inboxProvider);
  return inbox.where((m) => !m.isRead).length;
}

@Riverpod(keepAlive: true)
List<PocztaMessage> starredMessages(Ref ref) {
  final inbox = ref.watch(inboxProvider);
  return inbox.where((m) => m.isStarred).toList();
}

enum MessageFolder { inbox, sent, trash }

@Riverpod(keepAlive: true)
class SelectedFolder extends _$SelectedFolder {
  @override
  MessageFolder build() => MessageFolder.inbox;
  MessageFolder get value => state;
  set value(MessageFolder v) => state = v;
}

@Riverpod(keepAlive: true)
List<PocztaMessage> currentFolderMessages(Ref ref) {
  final folder = ref.watch(selectedFolderProvider);
  return switch (folder) {
    MessageFolder.inbox => ref.watch(inboxProvider),
    MessageFolder.sent => ref.watch(sentProvider),
    MessageFolder.trash => ref.watch(trashProvider),
  };
}
