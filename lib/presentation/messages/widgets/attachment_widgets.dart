import 'package:bsharp/domain/entities/outgoing_attachment.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/messages/attachments/attachment_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _bytesPerKilobyte = 1024;

String formatAttachmentSize(int sizeBytes, Locale locale) {
  const fallbackLocale = 'en';
  final localeName = Intl.verifiedLocale(
    locale.toString(),
    NumberFormat.localeExists,
    onFailure: (_) => fallbackLocale,
  );
  final format = NumberFormat('#,##0.#', localeName);
  if (sizeBytes < _bytesPerKilobyte) {
    return t.compose.sizeBytes(size: sizeBytes);
  }
  final kilobytes = sizeBytes / _bytesPerKilobyte;
  if (kilobytes < _bytesPerKilobyte) {
    return t.compose.sizeKilobytes(size: format.format(kilobytes));
  }
  return t.compose.sizeMegabytes(
    size: format.format(kilobytes / _bytesPerKilobyte),
  );
}

String uploadFailureReason(AttachmentUploadFailure failure) {
  return switch (failure) {
    AttachmentUploadFailure.tooLarge => t.compose.reasonTooLarge,
    AttachmentUploadFailure.unreadable => t.compose.reasonUnreadable,
    AttachmentUploadFailure.connection => t.compose.reasonConnection,
    AttachmentUploadFailure.timeout => t.compose.reasonTimeout,
    AttachmentUploadFailure.server => t.compose.reasonServer,
  };
}

String attachmentProblemText(AttachmentCheck check) {
  final name = check.attachment.name;
  return switch (check.problem) {
    AttachmentProblem.missing => t.compose.missing(name: name),
    AttachmentProblem.unreadable => t.compose.unreadable(name: name),
    AttachmentProblem.empty => t.compose.empty(name: name),
    AttachmentProblem.tooLarge => t.compose.tooLargeToSend(name: name),
  };
}

Future<AttachmentSource?> showAttachmentSourceSheet(
  BuildContext context, {
  required bool canUseCamera,
}) {
  return showModalBottomSheet<AttachmentSource>(
    context: context,
    builder: (context) {
      Widget option(AttachmentSource source, IconData icon, String label) {
        return ListTile(
          leading: Icon(icon),
          title: Text(label),
          onTap: () => Navigator.of(context).pop(source),
        );
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canUseCamera) ...[
              option(
                AttachmentSource.cameraPhoto,
                Icons.photo_camera_outlined,
                t.compose.cameraPhoto,
              ),
              option(
                AttachmentSource.cameraVideo,
                Icons.videocam_outlined,
                t.compose.cameraVideo,
              ),
            ],
            option(
              AttachmentSource.gallery,
              Icons.photo_library_outlined,
              t.compose.gallery,
            ),
            option(
              AttachmentSource.file,
              Icons.insert_drive_file_outlined,
              t.compose.file,
            ),
          ],
        ),
      );
    },
  );
}

class AttachmentChips extends StatelessWidget {
  const AttachmentChips({
    required this.attachments,
    required this.onRemove,
    super.key,
  });

  final List<OutgoingAttachment> attachments;
  final ValueChanged<OutgoingAttachment>? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final remove = onRemove;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final attachment in attachments)
          InputChip(
            avatar: const Icon(Icons.attach_file, size: 18),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(attachment.name, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 6),
                Text(
                  formatAttachmentSize(attachment.sizeBytes, locale),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            deleteButtonTooltipMessage: t.compose.remove(
              name: attachment.name,
            ),
            onDeleted: remove == null ? null : () => remove(attachment),
          ),
      ],
    );
  }
}

Future<void> showAttachmentProblemsDialog(
  BuildContext context,
  List<AttachmentCheck> problems,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.compose.notSent),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final problem in problems) Text(attachmentProblemText(problem)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.ok),
        ),
      ],
    ),
  );
}

Future<bool> showUploadFailureDialog(
  BuildContext context,
  List<AttachmentUploadResult> failed,
) async {
  final shouldRetry = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(t.compose.partialTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final AttachmentUploadResult(:attachment, :failure) in failed)
              if (failure != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.error_outline),
                  title: Text(attachment.name),
                  subtitle: Text(uploadFailureReason(failure)),
                ),
            const SizedBox(height: 8),
            Text(t.compose.partialBody),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(t.compose.done),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(t.common.retry),
        ),
      ],
    ),
  );
  return shouldRetry ?? false;
}
