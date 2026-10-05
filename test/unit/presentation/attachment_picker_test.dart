import 'dart:io';
import 'dart:typed_data';

import 'package:bsharp/domain/entities/outgoing_attachment.dart';
import 'package:bsharp/presentation/messages/attachments/attachment_picker.dart';
import 'package:bsharp/presentation/messages/widgets/attachment_widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('the camera is offered everywhere but on web', () {
    expect(PlatformAttachmentPicker(isWeb: false).canUseCamera, isTrue);
    expect(PlatformAttachmentPicker(isWeb: true).canUseCamera, isFalse);
  });

  test('a picked file on a device is sent from its path', () async {
    final file = File('${Directory.systemTemp.createTempSync().path}/a.jpg')
      ..writeAsBytesSync([1, 2, 3]);

    final attachment = await attachmentFromXFile(
      XFile(file.path),
      isWeb: false,
    );

    expect(attachment.name, 'a.jpg');
    expect(attachment.sizeBytes, 3);
    expect(attachment.path, file.path);
    expect(attachment.bytes, isNull);
  });

  test('a picked file on web is sent from its bytes', () async {
    final attachment = await attachmentFromXFile(
      XFile.fromData(
        Uint8List.fromList([4, 5]),
        name: 'scan.pdf',
        path: 'scan.pdf',
      ),
      isWeb: true,
    );

    expect(attachment.name, 'scan.pdf');
    expect(attachment.bytes, [4, 5]);
    expect(attachment.sizeBytes, 2);
  });

  test('a picked file over 50 MB is not loaded and is too large', () async {
    final attachment = await attachmentFromXFile(
      XFile.fromData(Uint8List(maxAttachmentBytes + 1), name: 'film.mov'),
      isWeb: true,
    );

    expect(attachment.isTooLarge, isTrue);
    expect(attachment.bytes, isNull);
    expect(attachment.path, isNull);
  });

  test('sizes read in the unit that fits', () {
    const english = Locale('en');

    expect(formatAttachmentSize(512, english), '512 B');
    expect(formatAttachmentSize(1536, english), '1.5 KB');
    expect(formatAttachmentSize(5 * 1024 * 1024, english), '5 MB');
    expect(formatAttachmentSize(1536, const Locale('pl')), '1,5 KB');
  });
}
