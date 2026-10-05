import 'package:bsharp/domain/entities/outgoing_attachment.dart';

typedef UploadPause = Future<void> Function(Duration delay);

typedef UploadAttempt = Future<AttachmentUploadFailure?> Function(
  OutgoingAttachment attachment,
);

class AttachmentUploader {
  const AttachmentUploader({this.pause = _wait});

  static const retryDelays = [Duration(seconds: 1), Duration(seconds: 3)];

  final UploadPause pause;

  static Future<void> _wait(Duration delay) => Future<void>.delayed(delay);

  Future<List<AttachmentUploadResult>> uploadAll(
    List<OutgoingAttachment> attachments,
    UploadAttempt attempt, {
    void Function(int index)? onUploading,
  }) async {
    final results = <AttachmentUploadResult>[];
    for (final (index, attachment) in attachments.indexed) {
      onUploading?.call(index);
      results.add(await _uploadWithRetries(attachment, attempt));
    }
    return results;
  }

  Future<AttachmentUploadResult> _uploadWithRetries(
    OutgoingAttachment attachment,
    UploadAttempt attempt,
  ) async {
    var failure = await attempt(attachment);
    for (final delay in retryDelays) {
      if (failure == null || !failure.isRetryable) {
        break;
      }
      await pause(delay);
      failure = await attempt(attachment);
    }
    if (failure == null) {
      return AttachmentUploadResult.uploaded(attachment);
    }
    return AttachmentUploadResult.failed(attachment, failure);
  }
}
