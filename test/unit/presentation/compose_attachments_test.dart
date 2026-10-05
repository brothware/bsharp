import 'dart:async';

import 'package:bsharp/app/attachment_providers.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/data/services/attachment_inspector.dart';
import 'package:bsharp/domain/attachment_uploader.dart';
import 'package:bsharp/domain/entities/outgoing_attachment.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/presentation/messages/attachments/attachment_picker.dart';
import 'package:bsharp/presentation/messages/widgets/attachment_widgets.dart';
import 'package:bsharp/presentation/messages/widgets/compose_message_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sentId = 777;

OutgoingAttachment _attachment(String name, {int sizeBytes = 1536}) {
  return OutgoingAttachment.memory(name: name, bytes: Uint8List(sizeBytes));
}

class _FakePicker implements AttachmentPicker {
  _FakePicker({this.canUseCamera = true});

  @override
  final bool canUseCamera;

  final requested = <AttachmentSource>[];
  List<OutgoingAttachment> nextPick = [];
  Exception? nextError;

  @override
  Future<List<OutgoingAttachment>> pick(AttachmentSource source) async {
    requested.add(source);
    final error = nextError;
    if (error != null) {
      throw error;
    }
    return nextPick;
  }
}

class _FakeInspector extends AttachmentInspector {
  final problems = <String, AttachmentProblem>{};

  @override
  Future<List<AttachmentCheck>> problemsWith(
    List<OutgoingAttachment> attachments,
  ) async {
    return [
      for (final attachment in attachments)
        if (problems[attachment.name] case final problem?)
          AttachmentCheck(attachment, problem),
    ];
  }
}

class _MailProvider extends DemoDataProvider {
  final sentTitles = <String>[];
  final uploadBatches = <List<String>>[];
  final attempts = <String>[];
  final scripted = <String, List<AttachmentUploadFailure>>{};
  bool isSessionDead = false;
  bool sendFails = false;
  bool answersNoId = false;
  Completer<void>? uploadGate;

  @override
  Future<void> ensureMailSession() async {
    if (isSessionDead) {
      throw const MessagingException(SessionExpired());
    }
  }

  @override
  Future<int> sendMessage({
    required List<String> recipientIds,
    required String title,
    required String content,
    int? previousMessageId,
  }) async {
    if (sendFails) {
      throw const MessagingException(SessionExpired());
    }
    sentTitles.add(title);
    if (answersNoId) {
      throw const SentWithoutIdException();
    }
    return _sentId;
  }

  @override
  Future<List<AttachmentUploadResult>> uploadAttachments(
    int messageId,
    List<OutgoingAttachment> attachments, {
    void Function(int index)? onUploading,
  }) {
    expect(messageId, _sentId);
    uploadBatches.add([for (final attachment in attachments) attachment.name]);
    return AttachmentUploader(pause: (_) async {}).uploadAll(attachments, (
      attachment,
    ) async {
      attempts.add(attachment.name);
      await uploadGate?.future;
      final outcomes = scripted[attachment.name];
      if (outcomes == null || outcomes.isEmpty) {
        return null;
      }
      return outcomes.removeAt(0);
    }, onUploading: onUploading);
  }
}

PocztaMessage _received() {
  return PocztaMessage(
    id: 5,
    title: 'Zebranie',
    senderName: 'Anna Nowak',
    sendTime: DateTime(2026, 10),
    isRead: true,
    isStarred: false,
  );
}

late SharedPreferences _prefs;

final Finder _attachmentChips = find.descendant(
  of: find.byType(AttachmentChips),
  matching: find.byType(InputChip),
);

Future<void> _openCompose(
  WidgetTester tester, {
  required _MailProvider provider,
  required _FakePicker picker,
  _FakeInspector? inspector,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(_prefs),
        activeDataProviderProvider.overrideWithBuild((ref, _) => provider),
        attachmentPickerProvider.overrideWithValue(picker),
        attachmentInspectorProvider.overrideWithValue(
          inspector ?? _FakeInspector(),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () =>
                  composeAndSend(context, ref, replyTo: _received()),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).last, 'Treść');
  await tester.pump();
}

Future<void> _attach(
  WidgetTester tester,
  _FakePicker picker,
  List<OutgoingAttachment> files,
) async {
  picker.nextPick = files;
  await tester.tap(find.byTooltip('Attach files'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Browse files'));
  await tester.pumpAndSettle();
}

Future<void> _tapSend(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.send));
  await tester.pumpAndSettle();
}

void main() {
  late _MailProvider provider;
  late _FakePicker picker;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
    provider = _MailProvider();
    picker = _FakePicker();
  });

  testWidgets('the paperclip opens every attachment source', (tester) async {
    await _openCompose(tester, provider: provider, picker: picker);

    expect(
      find.descendant(
        of: find.byTooltip('Attach files'),
        matching: find.byIcon(Icons.attach_file),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Attach files'));
    await tester.pumpAndSettle();

    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Record a video'), findsOneWidget);
    expect(find.text('Photos and videos'), findsOneWidget);
    expect(find.text('Browse files'), findsOneWidget);
  });

  testWidgets('each option asks the picker for its source', (tester) async {
    await _openCompose(tester, provider: provider, picker: picker);

    for (final label in [
      'Take a photo',
      'Record a video',
      'Photos and videos',
      'Browse files',
    ]) {
      await tester.tap(find.byTooltip('Attach files'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    expect(picker.requested, AttachmentSource.values);
  });

  testWidgets('without a camera the camera options are hidden', (
    tester,
  ) async {
    picker = _FakePicker(canUseCamera: false);
    await _openCompose(tester, provider: provider, picker: picker);

    await tester.tap(find.byTooltip('Attach files'));
    await tester.pumpAndSettle();

    expect(find.text('Take a photo'), findsNothing);
    expect(find.text('Record a video'), findsNothing);
    expect(find.text('Photos and videos'), findsOneWidget);
    expect(find.text('Browse files'), findsOneWidget);
  });

  testWidgets('a picked file shows its name and size and can be removed', (
    tester,
  ) async {
    await _openCompose(tester, provider: provider, picker: picker);

    await _attach(tester, picker, [_attachment('plan.pdf')]);

    expect(find.text('plan.pdf'), findsOneWidget);
    expect(find.text('1.5 KB'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove plan.pdf'));
    await tester.pumpAndSettle();

    expect(find.text('plan.pdf'), findsNothing);
  });

  testWidgets('a file over 50 MB is rejected with its name', (tester) async {
    await _openCompose(tester, provider: provider, picker: picker);

    await _attach(tester, picker, [
      const OutgoingAttachment.unloaded(
        name: 'film.mov',
        sizeBytes: maxAttachmentBytes + 1,
      ),
      _attachment('plan.pdf'),
    ]);

    expect(
      find.text('film.mov was not added: files can be at most 50 MB'),
      findsOneWidget,
    );
    expect(_attachmentChips, findsOneWidget);
    expect(find.text('plan.pdf'), findsOneWidget);
  });

  testWidgets('cancelling a picker changes nothing', (tester) async {
    await _openCompose(tester, provider: provider, picker: picker);

    await _attach(tester, picker, []);
    await tester.tap(find.byTooltip('Attach files'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(_attachmentChips, findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(picker.requested, [AttachmentSource.file]);
  });

  testWidgets('a picker that fails says so', (tester) async {
    await _openCompose(tester, provider: provider, picker: picker);
    picker.nextError = PlatformException(code: 'camera_access_denied');

    await tester.tap(find.byTooltip('Attach files'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();

    expect(find.text('Could not attach the file'), findsOneWidget);
  });

  testWidgets('sending uploads each file to the sent message and closes', (
    tester,
  ) async {
    await _openCompose(tester, provider: provider, picker: picker);
    await _attach(tester, picker, [_attachment('a.pdf'), _attachment('b.jpg')]);

    await _tapSend(tester);

    expect(provider.sentTitles, ['Re: Zebranie']);
    expect(provider.uploadBatches, [
      ['a.pdf', 'b.jpg'],
    ]);
    expect(find.byType(ComposeMessageView), findsNothing);
    expect(find.text('Message sent'), findsOneWidget);
  });

  testWidgets('uploads show progress and disable sending', (tester) async {
    await _openCompose(tester, provider: provider, picker: picker);
    await _attach(tester, picker, [_attachment('a.pdf'), _attachment('b.jpg')]);
    provider.uploadGate = Completer<void>();

    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump();

    expect(find.text('Uploading file 1 of 2'), findsOneWidget);
    final send = tester.widget<TextButton>(
      find.ancestor(
        of: find.byIcon(Icons.send),
        matching: find.byType(TextButton),
      ),
    );
    expect(send.onPressed, isNull);
    final popScope = tester.widget(
      find.descendant(
        of: find.byType(ComposeMessageView),
        matching: find.byWidgetPredicate((widget) => widget is PopScope),
      ),
    ) as PopScope;
    expect(popScope.canPop, isFalse);

    provider.uploadGate!.complete();
    await tester.pumpAndSettle();

    expect(find.byType(ComposeMessageView), findsNothing);
  });

  testWidgets('a transient upload failure that recovers shows no dialog', (
    tester,
  ) async {
    provider.scripted['a.pdf'] = [AttachmentUploadFailure.connection];
    await _openCompose(tester, provider: provider, picker: picker);
    await _attach(tester, picker, [_attachment('a.pdf')]);

    await _tapSend(tester);

    expect(provider.attempts, ['a.pdf', 'a.pdf']);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Message sent'), findsOneWidget);
  });

  testWidgets('a file too large for poczta goes straight to the dialog', (
    tester,
  ) async {
    provider.scripted['a.pdf'] = [AttachmentUploadFailure.tooLarge];
    await _openCompose(tester, provider: provider, picker: picker);
    await _attach(tester, picker, [_attachment('a.pdf')]);

    await _tapSend(tester);

    expect(provider.attempts, ['a.pdf']);
    expect(
      find.text('Message sent, but some files were not attached'),
      findsOneWidget,
    );
    expect(find.text('File too large'), findsOneWidget);
  });

  testWidgets('partial failure lists the failed file and Retry resends it', (
    tester,
  ) async {
    provider.scripted['b.jpg'] = List.filled(
      3,
      AttachmentUploadFailure.connection,
      growable: true,
    );
    await _openCompose(tester, provider: provider, picker: picker);
    await _attach(tester, picker, [_attachment('a.pdf'), _attachment('b.jpg')]);

    await _tapSend(tester);

    expect(provider.attempts.where((name) => name == 'b.jpg'), hasLength(3));
    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(of: dialog, matching: find.text('b.jpg')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('a.pdf')),
      findsNothing,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Connection lost')),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(provider.uploadBatches, [
      ['a.pdf', 'b.jpg'],
      ['b.jpg'],
    ]);
    expect(provider.sentTitles, hasLength(1));
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(ComposeMessageView), findsNothing);
  });

  testWidgets('Retry can be repeated while a file keeps failing', (
    tester,
  ) async {
    provider.scripted['b.jpg'] = List.filled(
      6,
      AttachmentUploadFailure.timeout,
      growable: true,
    );
    await _openCompose(tester, provider: provider, picker: picker);
    await _attach(tester, picker, [_attachment('b.jpg')]);

    await _tapSend(tester);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Upload timed out'), findsOneWidget);
    expect(provider.uploadBatches, hasLength(2));
  });

  testWidgets('Done closes compose and keeps the message sent', (
    tester,
  ) async {
    provider.scripted['a.pdf'] = [AttachmentUploadFailure.tooLarge];
    await _openCompose(tester, provider: provider, picker: picker);
    await _attach(tester, picker, [_attachment('a.pdf')]);

    await _tapSend(tester);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.byType(ComposeMessageView), findsNothing);
    expect(provider.sentTitles, hasLength(1));
    expect(provider.uploadBatches, hasLength(1));
  });

  for (final (problem, text) in [
    (AttachmentProblem.missing, 'a.pdf no longer exists'),
    (AttachmentProblem.unreadable, 'a.pdf cannot be read'),
    (AttachmentProblem.empty, 'a.pdf is empty'),
    (AttachmentProblem.tooLarge, 'a.pdf is larger than 50 MB'),
  ]) {
    testWidgets('a ${problem.name} file blocks the send', (tester) async {
      final inspector = _FakeInspector()..problems['a.pdf'] = problem;
      await _openCompose(
        tester,
        provider: provider,
        picker: picker,
        inspector: inspector,
      );
      await _attach(tester, picker, [_attachment('a.pdf')]);

      await _tapSend(tester);

      expect(find.text('Message not sent'), findsOneWidget);
      expect(find.text(text), findsOneWidget);
      expect(provider.sentTitles, isEmpty);
      expect(provider.uploadBatches, isEmpty);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(ComposeMessageView), findsOneWidget);
    });
  }

  testWidgets('a mailbox that cannot be reached blocks the send', (
    tester,
  ) async {
    provider.isSessionDead = true;
    await _openCompose(tester, provider: provider, picker: picker);
    await _attach(tester, picker, [_attachment('a.pdf')]);

    await _tapSend(tester);

    expect(
      find.text(
        'Message not sent: could not connect to the mailbox. Try again.',
      ),
      findsOneWidget,
    );
    expect(provider.sentTitles, isEmpty);
    expect(find.byType(ComposeMessageView), findsOneWidget);
  });

  testWidgets('a failed send uploads nothing and keeps compose open', (
    tester,
  ) async {
    provider.sendFails = true;
    await _openCompose(tester, provider: provider, picker: picker);
    await _attach(tester, picker, [_attachment('a.pdf')]);

    await _tapSend(tester);

    expect(find.text('Failed to send message'), findsOneWidget);
    expect(provider.uploadBatches, isEmpty);
    expect(find.byType(ComposeMessageView), findsOneWidget);
  });

  testWidgets('a message without files and without an id counts as sent', (
    tester,
  ) async {
    provider.answersNoId = true;
    await _openCompose(tester, provider: provider, picker: picker);

    await _tapSend(tester);

    expect(provider.sentTitles, hasLength(1));
    expect(find.byType(ComposeMessageView), findsNothing);
    expect(find.text('Message sent'), findsOneWidget);
    expect(find.text('Failed to send message'), findsNothing);
  });

  testWidgets('files for a message sent without an id are reported lost', (
    tester,
  ) async {
    provider.answersNoId = true;
    await _openCompose(tester, provider: provider, picker: picker);
    await _attach(tester, picker, [_attachment('a.pdf')]);

    await _tapSend(tester);

    expect(provider.sentTitles, hasLength(1));
    expect(provider.uploadBatches, isEmpty);
    expect(
      find.text('Message sent, but some files were not attached'),
      findsOneWidget,
    );
    expect(
      find.text(
        'The files could not be attached to this message. '
        'Send them in a new message.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsNothing);
    expect(find.text('Failed to send message'), findsNothing);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(ComposeMessageView), findsNothing);
    expect(find.text('Message sent'), findsOneWidget);
    expect(provider.sentTitles, hasLength(1));
  });

  testWidgets('a message without files is sent without a mailbox check', (
    tester,
  ) async {
    provider.isSessionDead = true;
    await _openCompose(tester, provider: provider, picker: picker);

    await _tapSend(tester);

    expect(provider.sentTitles, hasLength(1));
    expect(provider.uploadBatches, isEmpty);
    expect(find.text('Message sent'), findsOneWidget);
  });
}
