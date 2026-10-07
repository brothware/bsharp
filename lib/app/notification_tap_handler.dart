import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What happens when someone taps a notification, for whichever app they are
/// holding.
///
/// Deciding where a tap should land is the same reasoning on a phone and on a
/// watch: point at the right pupil, open the section the notification is
/// about, and then show the item itself if it can be worked out. Only the
/// opening differs, so only that is left to each app.
abstract class NotificationTapHandler {
  NotificationTapHandler({required this.ref});

  final WidgetRef ref;

  /// What was tapped, held until the sync it set off brings the item in.
  ChangeCategory? _awaitingReveal;
  int? _awaitingItemId;

  /// Watches the inbox for the named message, which can land there from the
  /// cache or from the mail part of the sync long before the sync is over.
  ProviderSubscription<List<PocztaMessage>>? _inboxWatch;

  /// Shows the section for [category]. Returns false when this app has nowhere
  /// to put it, in which case the tap is left alone.
  bool openSection(ChangeCategory category);

  /// Shows one message, on top of the section.
  bool openMessage(PocztaMessage message);

  void handleNotificationTap(NotificationPayload payload) {
    final category = payload.category;
    if (category == null) return;

    _selectPupil(payload);

    if (!openSection(category)) return;

    _stopAwaiting();
    _awaitingReveal = category;
    _awaitingItemId = payload.itemId;

    // A named item needs no working out: open it if it is already here, and
    // otherwise open it the moment it arrives.
    if (_reveal(category, payload.itemId)) {
      _stopAwaiting();
      return;
    }
    if (payload.itemId != null) {
      _inboxWatch = ref.listenManual(inboxProvider, (_, _) {
        if (_reveal(category, payload.itemId)) {
          _stopAwaiting();
        }
      });
    }
  }

  void _stopAwaiting() {
    _inboxWatch?.close();
    _inboxWatch = null;
    _awaitingReveal = null;
    _awaitingItemId = null;
  }

  /// The sync a tapped notification set off has finished, so the item it was
  /// about may have arrived.
  void handleSyncCompleted(ChangeSet changes) {
    final category = _awaitingReveal;
    final namedId = _awaitingItemId;
    _stopAwaiting();
    if (category == null) return;

    if (namedId != null) {
      _reveal(category, namedId);
      return;
    }

    // Nothing named an item, so the sync has to answer it: one thing of that
    // kind arrived means that is the one, anything else and the section stands.
    final arrived = changes.byCategory(category);
    if (arrived.length != 1) return;
    _reveal(category, arrived.single.entityId);
  }

  void _selectPupil(NotificationPayload payload) {
    final accountId = payload.accountId;
    final studentId = payload.studentId;
    if (accountId == null || studentId == null) return;

    final current = ref.read(activeSelectionProvider).value;
    if (current?.accountId == accountId && current?.studentId == studentId) {
      return;
    }

    unawaited(
      ref
          .read(activeSelectionProvider.notifier)
          .select(ActiveSelection(accountId: accountId, studentId: studentId)),
    );
  }

  /// Opens the item itself, and reports whether it managed to.
  bool _reveal(ChangeCategory category, int? itemId) {
    if (itemId == null || category != ChangeCategory.messages) return false;

    final message = ref
        .read(inboxProvider)
        .where((m) => m.id == itemId)
        .firstOrNull;
    if (message == null) return false;

    return openMessage(message);
  }
}
