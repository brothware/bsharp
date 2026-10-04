import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/data/providers/mobireg/parsers/json_fields.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

List<PocztaMessage> parsePocztaMessages(List<dynamic> data, String folder) {
  final view = 'poczta $folder';
  return objectsOf(data, view).map((item) {
    final author = item['author'];
    final recipients = item['recipients'];
    return PocztaMessage(
      id: intField(item, 'id', view),
      title: item['subject'] as String? ?? '',
      senderName: author is Map<String, dynamic>
          ? author['name'] as String? ?? ''
          : '',
      sendTime: _dateTimeField(item, 'date', view),
      preview: item['content'] as String?,
      isRead: item['read_at'] != null,
      isStarred: item['stared'] == true,
      content: item['content'] as String?,
      recipients: recipients == null
          ? const []
          : objectsOf(recipients, view).map(_recipientOf).toList(),
    );
  }).toList();
}

PocztaRecipient _recipientOf(Map<String, dynamic> json) {
  final readAt = json['read_at'] as String?;
  return PocztaRecipient(
    name: json['name'] as String? ?? '',
    role: json['roleName'] as String?,
    readAt: readAt != null ? DateTime.tryParse(readAt) : null,
  );
}

DateTime _dateTimeField(Map<String, dynamic> json, String key, String view) {
  final raw = stringField(json, key, view);
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    throw FormatException('View $view: "$key" is not a date', json);
  }
  return parsed;
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
