@TestOn('vm')
@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:bsharp/data/providers/mobireg/mobireg_message_handler.dart';
import 'package:bsharp/data/services/sync_data_parser.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _mockBaseUrl = 'http://localhost:8090';

Future<bool> _isMockRunning() async {
  try {
    final socket = await Socket.connect(
      'localhost',
      8090,
      timeout: const Duration(seconds: 1),
    );
    socket.destroy();
    return true;
  } on Object {
    return false;
  }
}

void main() {
  late Dio dio;
  late bool mockAvailable;

  setUpAll(() async {
    mockAvailable = await _isMockRunning();
    if (!mockAvailable) {
      markTestSkipped(
        'mobireg-mock not running on localhost:8090. '
        'Start with: cd lib/data/providers/mobireg/test-mock && npm start',
      );
      return;
    }
    dio = Dio(
      BaseOptions(
        baseUrl: _mockBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
  });

  tearDownAll(() => dio.close());

  group('Mobile Sync', () {
    test('Settings response parses correctly', () async {
      final response = await dio.post<Map<String, dynamic>>(
        '/osm-wroclaw/modules/api/njson.php',
        data: 'login=eparent&pass=test&view=Settings',
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      final data = response.data!;
      expect(data, contains('Settings'));
      final settings = data['Settings'] as List;
      expect(settings, isNotEmpty);
      final first = settings.first as Map<String, dynamic>;
      expect(first['schoolName'], isA<String>());
      expect(first['version'], isA<String>());
      expect(first['protocol'], isA<String>());
    });

    test('ParentStudents response parses correctly', () async {
      final response = await dio.post<Map<String, dynamic>>(
        '/osm-wroclaw/modules/api/njson.php',
        data: 'login=eparent&pass=test&view=ParentStudents',
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      final data = response.data!;
      expect(data, contains('ParentStudents'));
      final students = data['ParentStudents'] as List;
      expect(students, isNotEmpty);
      final first = students.first as Map<String, dynamic>;
      expect(first['id'], isA<int>());
      expect(first['name'], isA<String>());
      expect(first['surname'], isA<String>());
      expect(first['sex'], isA<String>());
    });

    test('Full sync response parses through SyncDataParser', () async {
      final response = await dio.post<Map<String, dynamic>>(
        '/osm-wroclaw/modules/api/njson.php',
        data:
            'login=eparent&pass=test&student_id=6541&start_date=2025-09-01&end_date=2026-06-30',
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      final data = response.data!;
      final parser = SyncDataParser();
      final syncData = parser.parse(data);

      expect(
        syncData.students,
        isNotEmpty,
        reason: 'Students should not be empty',
      );
      expect(
        syncData.teachers,
        isNotEmpty,
        reason: 'Teachers should not be empty',
      );
      expect(
        syncData.subjects,
        isNotEmpty,
        reason: 'Subjects should not be empty',
      );
      expect(syncData.events, isNotEmpty, reason: 'Events should not be empty');
      expect(syncData.marks, isNotEmpty, reason: 'Marks should not be empty');
      expect(
        syncData.attendances,
        isNotEmpty,
        reason: 'Attendances should not be empty',
      );
      expect(
        syncData.attendanceTypes,
        isNotEmpty,
        reason: 'AttendanceTypes should not be empty',
      );

      expect(syncData.students.first.name, isNotEmpty);
      expect(syncData.teachers.first.name, isNotEmpty);
      expect(syncData.subjects.first.name, isNotEmpty);
    });
  });

  group('Portal API', () {
    test('subjects view parses correctly', () async {
      final response = await dio.post<Map<String, dynamic>>(
        '/api.php',
        data: 'school=osm-wroclaw&token=abc&view=subjects&pupilId=6541',
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      final items = response.data!['items'] as List;
      expect(items, isNotEmpty);
      final first = items.first as Map<String, dynamic>;
      expect(first['id'], isA<int>());
      expect(first['name'], isA<String>());
    });

    test('timetable-events view parses correctly', () async {
      final response = await dio.post<Map<String, dynamic>>(
        '/api.php',
        data:
            'school=osm-wroclaw&token=abc&view=timetable-events&pupilId=6541&dateFrom=2026-03-01&dateTo=2026-03-31',
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      final items = response.data!['items'] as List;
      expect(items, isNotEmpty);
      final first = items.first as Map<String, dynamic>;
      expect(first['id'], isA<int>());
      expect(first['dateTimeFrom'], isA<String>());
      expect(first['subjectName'], isA<String>());
      expect(first['teachers'], isA<List<dynamic>>());
    });

    test('marks view parses correctly', () async {
      final response = await dio.post<Map<String, dynamic>>(
        '/api.php',
        data: 'school=osm-wroclaw&token=abc&view=marks&pupilId=6541&termId=1',
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      final items = response.data!['items'] as List;
      expect(items, isNotEmpty);
      final first = items.first as Map<String, dynamic>;
      expect(first['id'], isA<int>());
      expect(first['value'], isA<String>());
      expect(first['subjectId'], isA<int>());
      expect(first['weight'], isA<int>());
    });

    test('homeworks view parses correctly', () async {
      final response = await dio.post<Map<String, dynamic>>(
        '/api.php',
        data: 'school=osm-wroclaw&token=abc&view=homeworks&pupilId=6541',
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      final items = response.data!['items'] as List;
      expect(items, isNotEmpty);
      final first = items.first as Map<String, dynamic>;
      expect(first['id'], isA<int>());
      expect(first['subjectName'], isA<String>());
      expect(first['dueDate'], isA<String>());
    });

    test('attendances view parses correctly', () async {
      final response = await dio.post<Map<String, dynamic>>(
        '/api.php',
        data: 'school=osm-wroclaw&token=abc&view=attendances&pupilId=6541',
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      final data = response.data!;
      expect(data['percent'], isA<num>());
      expect(data['types'], isA<List<dynamic>>());
    });
  });

  group('Poczta Messages', () {
    test('inbox parses through PocztaMessage parser', () async {
      final response = await dio.post<String>(
        '/api/messages/inbox',
        data: jsonEncode({'page': 1}),
        options: Options(
          contentType: 'application/json',
          responseType: ResponseType.plain,
        ),
      );

      final decoded = jsonDecode(response.data!) as List;
      expect(decoded, isNotEmpty);

      final messages = parsePocztaMessages(decoded);
      expect(messages, isNotEmpty);
      expect(messages.first.title, isNotEmpty);
      expect(messages.first.senderName, isNotEmpty);
    });

    test('sent parses correctly', () async {
      final response = await dio.post<String>(
        '/api/messages/sent',
        data: jsonEncode({'page': 1}),
        options: Options(
          contentType: 'application/json',
          responseType: ResponseType.plain,
        ),
      );

      final decoded = jsonDecode(response.data!) as List;
      expect(decoded, isNotEmpty);
      final messages = parsePocztaMessages(decoded);
      expect(messages, isNotEmpty);
    });

    test('read message returns full content', () async {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/messages/read/20001',
      );

      final data = response.data!;
      expect(data['id'], isA<int>());
      expect(data['subject'], isA<String>());
      expect(data['content'], isA<String>());
      expect(data['author'], isA<Map<String, dynamic>>());
      expect((data['author'] as Map)['name'], isA<String>());
    });

    test('receivers search returns results', () async {
      final response = await dio.post<List<dynamic>>(
        '/api/messages/receivers/search',
        data: jsonEncode({'query': 'Kowalska'}),
        options: Options(contentType: 'application/json'),
      );

      final data = response.data!;
      expect(data, isNotEmpty);
      final first = data.first as Map<String, dynamic>;
      expect(first['id'], isA<String>());
      expect(first['name'], isA<String>());
    });
  });
}
