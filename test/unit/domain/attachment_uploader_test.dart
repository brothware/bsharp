import 'dart:typed_data';

import 'package:bsharp/domain/attachment_uploader.dart';
import 'package:bsharp/domain/entities/outgoing_attachment.dart';
import 'package:flutter_test/flutter_test.dart';

OutgoingAttachment _attachment(String name) {
  return OutgoingAttachment.memory(
    name: name,
    bytes: Uint8List.fromList([1, 2, 3]),
  );
}

class _ScriptedUpload {
  _ScriptedUpload(this.script);

  final Map<String, List<AttachmentUploadFailure?>> script;
  final attempts = <String>[];

  Future<AttachmentUploadFailure?> call(OutgoingAttachment attachment) async {
    attempts.add(attachment.name);
    final outcomes = script[attachment.name];
    if (outcomes == null || outcomes.isEmpty) {
      return null;
    }
    return outcomes.removeAt(0);
  }
}

void main() {
  late List<Duration> pauses;
  late AttachmentUploader uploader;

  setUp(() {
    pauses = [];
    uploader = AttachmentUploader(pause: (delay) async => pauses.add(delay));
  });

  test('uploads every file in order and reports which one is next', () async {
    final upload = _ScriptedUpload({});
    final started = <int>[];

    final results = await uploader.uploadAll(
      [_attachment('a.pdf'), _attachment('b.pdf')],
      upload.call,
      onUploading: started.add,
    );

    expect(upload.attempts, ['a.pdf', 'b.pdf']);
    expect(started, [0, 1]);
    expect(results.every((result) => result.isUploaded), isTrue);
    expect(pauses, isEmpty);
  });

  test(
    'a transient failure that succeeds on the second try is uploaded',
    () async {
      final upload = _ScriptedUpload({
        'a.pdf': [AttachmentUploadFailure.connection],
      });

      final results = await uploader.uploadAll([
        _attachment('a.pdf'),
      ], upload.call);

      expect(results.single.isUploaded, isTrue);
      expect(upload.attempts, ['a.pdf', 'a.pdf']);
      expect(pauses, [const Duration(seconds: 1)]);
    },
  );

  test('a file that is too large is not retried', () async {
    final upload = _ScriptedUpload({
      'big.mov': [AttachmentUploadFailure.tooLarge],
    });

    final results = await uploader.uploadAll(
      [_attachment('big.mov')],
      upload.call,
    );

    expect(results.single.failure, AttachmentUploadFailure.tooLarge);
    expect(upload.attempts, ['big.mov']);
    expect(pauses, isEmpty);
  });

  test('an unreadable file is not retried', () async {
    final upload = _ScriptedUpload({
      'gone.pdf': [AttachmentUploadFailure.unreadable],
    });

    final results = await uploader.uploadAll(
      [_attachment('gone.pdf')],
      upload.call,
    );

    expect(results.single.failure, AttachmentUploadFailure.unreadable);
    expect(upload.attempts, ['gone.pdf']);
  });

  test('a file failing all three attempts reports its last reason', () async {
    final upload = _ScriptedUpload({
      'a.pdf': [
        AttachmentUploadFailure.connection,
        AttachmentUploadFailure.server,
        AttachmentUploadFailure.timeout,
      ],
    });

    final results = await uploader.uploadAll([
      _attachment('a.pdf'),
    ], upload.call);

    expect(results.single.failure, AttachmentUploadFailure.timeout);
    expect(upload.attempts, ['a.pdf', 'a.pdf', 'a.pdf']);
    expect(pauses, [const Duration(seconds: 1), const Duration(seconds: 3)]);
  });

  test('a failed file does not stop the next one', () async {
    final upload = _ScriptedUpload({
      'big.mov': [AttachmentUploadFailure.tooLarge],
    });

    final results = await uploader.uploadAll(
      [_attachment('big.mov'), _attachment('b.pdf')],
      upload.call,
    );

    expect(results.map((result) => result.isUploaded), [false, true]);
    expect(results.map((result) => result.attachment.name), [
      'big.mov',
      'b.pdf',
    ]);
  });
}
