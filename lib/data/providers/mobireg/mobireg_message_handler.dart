import 'package:bsharp/domain/entities/poczta.dart';

List<PocztaMessage> parsePocztaMessages(List<dynamic> data) {
  final result = <PocztaMessage>[];
  for (final item in data) {
    if (item is! Map<String, dynamic>) continue;
    try {
      final author = item['author'] as Map<String, dynamic>?;
      final senderName = author?['name'] as String? ?? '';

      final dateStr = item['date'] as String?;
      if (dateStr == null) continue;

      final recipientsRaw = item['recipients'] as List<dynamic>?;
      final recipients = <PocztaRecipient>[];
      if (recipientsRaw != null) {
        for (final r in recipientsRaw) {
          if (r is! Map<String, dynamic>) continue;
          final readAtStr = r['read_at'] as String?;
          recipients.add(
            PocztaRecipient(
              name: (r['name'] ?? '') as String,
              role: r['roleName'] as String?,
              readAt: readAtStr != null ? DateTime.tryParse(readAtStr) : null,
            ),
          );
        }
      }

      result.add(
        PocztaMessage(
          id: item['id'] as int,
          title: (item['subject'] ?? '') as String,
          senderName: senderName,
          sendTime: DateTime.parse(dateStr),
          preview: item['content'] as String?,
          isRead: item['read_at'] != null,
          isStarred: item['stared'] == true,
          content: item['content'] as String?,
          recipients: recipients,
        ),
      );
    } on Object {
      continue;
    }
  }
  return result;
}
