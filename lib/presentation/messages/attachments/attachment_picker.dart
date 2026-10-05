import 'package:bsharp/domain/entities/outgoing_attachment.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum AttachmentSource { cameraPhoto, cameraVideo, gallery, file }

abstract interface class AttachmentPicker {
  bool get canUseCamera;

  Future<List<OutgoingAttachment>> pick(AttachmentSource source);
}

final attachmentPickerProvider = Provider<AttachmentPicker>(
  (ref) => PlatformAttachmentPicker(),
);

class PlatformAttachmentPicker implements AttachmentPicker {
  PlatformAttachmentPicker({ImagePicker? imagePicker, this.isWeb = kIsWeb})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;
  final bool isWeb;

  @override
  bool get canUseCamera => !isWeb;

  @override
  Future<List<OutgoingAttachment>> pick(AttachmentSource source) async {
    final files = switch (source) {
      AttachmentSource.cameraPhoto => [
        ?await _imagePicker.pickImage(
          source: ImageSource.camera,
          requestFullMetadata: false,
        ),
      ],
      AttachmentSource.cameraVideo => [
        ?await _imagePicker.pickVideo(source: ImageSource.camera),
      ],
      AttachmentSource.gallery => await _imagePicker.pickMultipleMedia(
        requestFullMetadata: false,
      ),
      AttachmentSource.file => [
        for (final file in await FilePicker.pickFiles()) file.xFile,
      ],
    };
    return [
      for (final file in files) await attachmentFromXFile(file, isWeb: isWeb),
    ];
  }
}

Future<OutgoingAttachment> attachmentFromXFile(
  XFile file, {
  required bool isWeb,
}) async {
  final sizeBytes = await file.length();
  if (sizeBytes > maxAttachmentBytes) {
    return OutgoingAttachment.unloaded(name: file.name, sizeBytes: sizeBytes);
  }
  if (isWeb) {
    return OutgoingAttachment.memory(
      name: file.name,
      bytes: await file.readAsBytes(),
    );
  }
  return OutgoingAttachment.file(
    name: file.name,
    sizeBytes: sizeBytes,
    path: file.path,
  );
}
