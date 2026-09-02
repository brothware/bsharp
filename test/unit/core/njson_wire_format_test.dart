import 'dart:convert';
import 'dart:typed_data';

import 'package:bsharp/core/constants/app_constants.dart';
import 'package:bsharp/core/network/api_client_factory.dart';
import 'package:bsharp/data/data_sources/remote/mobile_sync_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? captured;
  String? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      body = utf8.decode(chunks.expand((c) => c).toList());
    }
    return ResponseBody.fromString(
      '{"ParentStudents":[]}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  ApiClientFactory factory() => ApiClientFactory(
    school: 'osm-wroclaw',
    parentLogin: 'dsliwa',
    parentPassHash: 'deadbeef',
  );

  const credentials =
      'login=eparent&pass=eparent&device_id=1&app_version=95'
      '&parent_login=dsliwa&parent_pass=deadbeef';

  Future<_CapturingAdapter> capture(
    Dio client,
    Future<void> Function(MobileSyncDataSource) call,
  ) async {
    final adapter = _CapturingAdapter();
    client.httpClientAdapter = adapter;
    await call(MobileSyncDataSource(client: client));
    return adapter;
  }

  group('njson.php wire format', () {
    test(
      'sync requests carry the credentials before the view fields',
      () async {
        final adapter = await capture(
          factory().createMobileSyncClient(),
          (ds) => ds.getSettings(),
        );

        expect(adapter.body, '$credentials&view=Settings');
      },
    );

    test('full sync sends the dates before the import parameters', () async {
      final adapter = await capture(
        factory().createMobileSyncClient(),
        (ds) => ds.fullSync(
          studentId: 6541,
          startDate: '2025-09-01',
          endDate: '2026-08-31',
        ),
      );

      expect(
        adapter.body,
        '$credentials&start_date=2025-09-01&end_date=2026-08-31'
        '&get_all_mark_groups=1&student_id=6541',
      );
    });

    test('diff sync orders last_end_date before lmt', () async {
      final adapter = await capture(
        factory().createMobileSyncClient(),
        (ds) => ds.diffSync(
          studentId: 6541,
          startDate: '2025-09-01',
          endDate: '2026-08-31',
          lastModificationTime: '2026-09-01 12:00:00',
          lastEndDate: '2026-08-30',
        ),
      );

      expect(
        adapter.body,
        contains('&end_date=2026-08-31&last_end_date=2026-08-30&lmt='),
      );
      expect(adapter.body, endsWith('&get_all_mark_groups=1&student_id=6541'));
    });

    test('the sync client uses the andreg headers', () async {
      final adapter = await capture(
        factory().createMobileSyncClient(),
        (ds) => ds.getSettings(),
      );
      final headers = adapter.captured!.headers;

      expect(headers['User-Agent'], AppConstants.userAgent);
      expect(headers['Accept-Encoding'], 'gzip,deflate');
      expect(
        adapter.captured!.contentType,
        'application/x-www-form-urlencoded; charset=UTF-8',
      );
    });

    test('the token upload uses the okhttp headers', () async {
      final adapter = await capture(
        factory().createTokenUploadClient(),
        (ds) => ds.registerFcmToken(token: 'fcm-token'),
      );
      final headers = adapter.captured!.headers;

      expect(headers['User-Agent'], 'okhttp/4.9.3');
      expect(headers['Accept-Encoding'], 'gzip');
      expect(
        adapter.captured!.contentType,
        'application/x-www-form-urlencoded',
      );
      expect(adapter.body, '$credentials&view=ParentStudents&token=fcm-token');
    });
  });
}
