import 'package:flutter/foundation.dart';

const maxAttachmentBytes = 52428800;

@immutable
class OutgoingAttachment {
  const OutgoingAttachment.file({
    required this.name,
    required this.sizeBytes,
    required String this.path,
  }) : bytes = null;

  factory OutgoingAttachment.memory({
    required String name,
    required Uint8List bytes,
  }) {
    return OutgoingAttachment._(
      name: name,
      sizeBytes: bytes.length,
      bytes: bytes,
    );
  }

  const OutgoingAttachment.unloaded({
    required this.name,
    required this.sizeBytes,
  }) : path = null,
       bytes = null;

  const OutgoingAttachment._({
    required this.name,
    required this.sizeBytes,
    this.bytes,
  }) : path = null;

  final String name;
  final int sizeBytes;
  final String? path;
  final Uint8List? bytes;

  bool get isTooLarge => sizeBytes > maxAttachmentBytes;
}

enum AttachmentUploadFailure {
  tooLarge,
  unreadable,
  connection,
  timeout,
  server;

  bool get isRetryable => this != tooLarge && this != unreadable;
}

@immutable
class AttachmentUploadResult {
  const AttachmentUploadResult.uploaded(this.attachment) : failure = null;

  const AttachmentUploadResult.failed(
    this.attachment,
    AttachmentUploadFailure this.failure,
  );

  final OutgoingAttachment attachment;
  final AttachmentUploadFailure? failure;

  bool get isUploaded => failure == null;
}

enum AttachmentProblem { missing, unreadable, empty, tooLarge }

@immutable
class AttachmentCheck {
  const AttachmentCheck(this.attachment, this.problem);

  final OutgoingAttachment attachment;
  final AttachmentProblem problem;
}
