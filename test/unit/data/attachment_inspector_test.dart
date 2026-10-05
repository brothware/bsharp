import 'dart:io';
import 'dart:typed_data';

import 'package:bsharp/data/services/attachment_inspector.dart';
import 'package:bsharp/domain/entities/outgoing_attachment.dart';
import 'package:flutter_test/flutter_test.dart';

OutgoingAttachment _onDisk(String name, List<int> content) {
  final file = File('${Directory.systemTemp.createTempSync().path}/$name')
    ..writeAsBytesSync(content);
  return OutgoingAttachment.file(
    name: name,
    sizeBytes: content.length,
    path: file.path,
  );
}

void main() {
  const inspector = AttachmentInspector();

  test('a readable file on disk is sendable', () async {
    expect(await inspector.problemWith(_onDisk('a.pdf', [1, 2])), isNull);
  });

  test('a file deleted after picking is missing', () async {
    final attachment = _onDisk('a.pdf', [1]);
    File(attachment.path!).deleteSync();

    expect(await inspector.problemWith(attachment), AttachmentProblem.missing);
  });

  test('a file emptied after picking is empty', () async {
    final attachment = _onDisk('a.pdf', [1]);
    File(attachment.path!).writeAsBytesSync([]);

    expect(await inspector.problemWith(attachment), AttachmentProblem.empty);
  });

  test('a file that grew past 50 MB is too large', () async {
    final attachment = _onDisk('a.mov', [1]);
    File(attachment.path!).writeAsBytesSync(Uint8List(maxAttachmentBytes + 1));

    expect(
      await inspector.problemWith(attachment),
      AttachmentProblem.tooLarge,
    );
  });

  test('a file without read permission is unreadable', () async {
    final attachment = _onDisk('a.pdf', [1]);
    final chmod = Process.runSync('chmod', ['000', attachment.path!]);
    expect(chmod.exitCode, 0);
    addTearDown(() => Process.runSync('chmod', ['600', attachment.path!]));

    expect(
      await inspector.problemWith(attachment),
      AttachmentProblem.unreadable,
    );
  }, skip: Platform.isWindows);

  test('picked bytes are checked for size', () async {
    expect(
      await inspector.problemWith(
        OutgoingAttachment.memory(name: 'a.pdf', bytes: Uint8List(3)),
      ),
      isNull,
    );
    expect(
      await inspector.problemWith(
        OutgoingAttachment.memory(name: 'a.pdf', bytes: Uint8List(0)),
      ),
      AttachmentProblem.empty,
    );
  });

  test('an attachment with neither a path nor bytes is missing', () async {
    expect(
      await inspector.problemWith(
        const OutgoingAttachment.unloaded(
          name: 'a.mov',
          sizeBytes: maxAttachmentBytes + 1,
        ),
      ),
      AttachmentProblem.missing,
    );
  });

  test('only the files with a problem are reported', () async {
    final good = _onDisk('good.pdf', [1]);
    final empty = _onDisk('empty.pdf', []);

    final problems = await inspector.problemsWith([good, empty]);

    expect(problems.single.attachment, empty);
    expect(problems.single.problem, AttachmentProblem.empty);
  });
}
