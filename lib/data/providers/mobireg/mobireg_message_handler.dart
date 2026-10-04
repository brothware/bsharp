import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

List<PocztaMessage> parsePocztaMessages(List<dynamic> data, String folder) {
  final view = 'poczta $folder';
  return _objectsOf(data, view).map((item) {
    final author = item['author'];
    final recipients = item['recipients'];
    return PocztaMessage(
      id: _idOf(item, view),
      title: item['subject'] as String? ?? '',
      senderName: author is Map<String, dynamic>
          ? author['name'] as String? ?? ''
          : '',
      sendTime: _dateOf(item, view),
      preview: item['content'] as String?,
      isRead: item['read_at'] != null,
      isStarred: item['stared'] == true,
      recipients: recipients == null
          ? const []
          : _objectsOf(recipients as Object, view).map(_recipientOf).toList(),
    );
  }).toList();
}

List<Map<String, dynamic>> _objectsOf(Object data, String view) {
  if (data is! List) {
    throw FormatException('View $view: expected a list', data.runtimeType);
  }
  return data.map((item) {
    if (item is! Map<String, dynamic>) {
      throw FormatException('View $view: expected objects', item.runtimeType);
    }
    return item;
  }).toList();
}

int _idOf(Map<String, dynamic> item, String view) {
  final id = item['id'];
  if (id is! int) {
    throw FormatException('View $view: "id" is not an int', item.keys.toList());
  }
  return id;
}

DateTime _dateOf(Map<String, dynamic> item, String view) {
  final raw = item['date'];
  final parsed = raw is String ? DateTime.tryParse(raw) : null;
  if (parsed == null) {
    throw FormatException(
      'View $view: "date" is not a date, message ${item['id']}',
      item.keys.toList(),
    );
  }
  return parsed;
}

PocztaRecipient _recipientOf(Map<String, dynamic> json) {
  final readAt = json['read_at'] as String?;
  return PocztaRecipient(
    name: json['name'] as String? ?? '',
    role: json['roleName'] as String?,
    readAt: readAt != null ? DateTime.tryParse(readAt) : null,
  );
}

void applyMessages(Ref ref, String folder, List<dynamic> data) {
  final messages = parsePocztaMessages(data, folder);
  switch (folder) {
    case 'inbox':
      ref.read(inboxProvider.notifier).value = messages;
    case 'sent':
      ref.read(sentProvider.notifier).value = messages;
    case 'trash':
      ref.read(trashProvider.notifier).value = messages;
  }
}
