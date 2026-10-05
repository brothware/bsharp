import 'package:bsharp/data/services/attachment_inspector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final attachmentInspectorProvider = Provider<AttachmentInspector>(
  (ref) => const AttachmentInspector(),
);
