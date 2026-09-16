import 'package:bsharp/data/providers/mobireg/mobireg_data_provider.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final provider = MobiregDataProvider();

  RemoteMessage messageOfKind(String kind) => RemoteMessage(
    data: {'title': 'Title', 'body': 'Body', 'kind': kind},
  );

  group('MobiregDataProvider.parseFcmMessage', () {
    test('renders every kind the server can send', () {
      const kindToCategory = <String, ChangeCategory?>{
        'messages': ChangeCategory.messages,
        'marks': ChangeCategory.grades,
        'absences': ChangeCategory.attendance,
        'reprimands': ChangeCategory.notes,
        'timetables': ChangeCategory.schedule,
        'substitutions': ChangeCategory.schedule,
        'cancellations': ChangeCategory.schedule,
        'planChanges': ChangeCategory.schedule,
        'exams': ChangeCategory.tests,
        'announcements': ChangeCategory.bulletins,
        'other': null,
      };

      for (final entry in kindToCategory.entries) {
        final spec = provider.parseFcmMessage(messageOfKind(entry.key));
        expect(spec, isNotNull, reason: 'kind ${entry.key} was dropped');
        expect(spec!.category, entry.value, reason: 'kind ${entry.key}');
        expect(spec.channelId, isNotEmpty);
        expect(spec.channelName, isNotEmpty);
      }
    });

    test('gives each kind its own notification channel', () {
      const kinds = [
        'messages',
        'marks',
        'absences',
        'reprimands',
        'timetables',
      ];
      final channels = kinds
          .map((k) => provider.parseFcmMessage(messageOfKind(k))!.channelId)
          .toSet();

      expect(channels.length, kinds.length);
    });

    test('treats an unrecognized kind as the fallback kind', () {
      final spec = provider.parseFcmMessage(messageOfKind('somethingNew'));

      expect(spec, isNotNull);
      expect(spec!.category, isNull);
    });

    test('drops a message with no title', () {
      const message = RemoteMessage(data: {'body': 'Body', 'kind': 'marks'});

      expect(provider.parseFcmMessage(message), isNull);
    });

    test('honors noSync', () {
      final syncing = provider.parseFcmMessage(messageOfKind('marks'));
      final quiet = provider.parseFcmMessage(
        const RemoteMessage(
          data: {'title': 'T', 'body': 'B', 'kind': 'marks', 'noSync': 'true'},
        ),
      );

      expect(syncing!.triggersSync, isTrue);
      expect(quiet!.triggersSync, isFalse);
    });
  });
}
