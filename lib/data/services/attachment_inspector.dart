import 'dart:io';

import 'package:bsharp/domain/entities/outgoing_attachment.dart';
import 'package:flutter/foundation.dart';

class AttachmentInspector {
  const AttachmentInspector();

  Future<List<AttachmentCheck>> problemsWith(
    List<OutgoingAttachment> attachments,
  ) async {
    return [
      for (final attachment in attachments)
        if (await problemWith(attachment) case final problem?)
          AttachmentCheck(attachment, problem),
    ];
  }

  Future<AttachmentProblem?> problemWith(OutgoingAttachment attachment) async {
    final bytes = attachment.bytes;
    if (bytes != null) {
      return _sizeProblem(bytes.length);
    }
    final path = attachment.path;
    if (path == null) {
      return AttachmentProblem.missing;
    }
    final file = File(path);
    if (!file.existsSync()) {
      return AttachmentProblem.missing;
    }
    try {
      final handle = await file.open();
      try {
        return _sizeProblem(await handle.length());
      } finally {
        await handle.close();
      }
    } on FileSystemException catch (error) {
      debugPrint(
        'AttachmentInspector: ${attachment.name} is unreadable: $error',
      );
      return AttachmentProblem.unreadable;
    }
  }

  AttachmentProblem? _sizeProblem(int length) {
    if (length == 0) {
      return AttachmentProblem.empty;
    }
    if (length > maxAttachmentBytes) {
      return AttachmentProblem.tooLarge;
    }
    return null;
  }
}
