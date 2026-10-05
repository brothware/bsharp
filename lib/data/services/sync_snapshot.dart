import 'dart:convert';

import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncSnapshot {
  const SyncSnapshot({
    this.markIds = const {},
    this.eventIds = const {},
    this.attendanceIds = const {},
    this.homeworkIds = const {},
    this.testIds = const {},
    this.reprimandIds = const {},
    this.inboxMessageIds = const {},
    this.isInboxBaselineKnown = true,
  });

  factory SyncSnapshot.fromJson(Map<String, dynamic> json) {
    return SyncSnapshot(
      markIds: _intSet(json['markIds']),
      eventIds: _intSet(json['eventIds']),
      attendanceIds: _intSet(json['attendanceIds']),
      homeworkIds: _intSet(json['homeworkIds']),
      testIds: _intSet(json['testIds']),
      reprimandIds: _intSet(json['reprimandIds']),
      inboxMessageIds: _intSet(json['inboxMessageIds']),
      isInboxBaselineKnown: switch (json['isInboxBaselineKnown']) {
        final bool isKnown => isKnown,
        null => true,
        final other => throw FormatException(
          'isInboxBaselineKnown is not a bool',
          other,
        ),
      },
    );
  }

  final Set<int> markIds;
  final Set<int> eventIds;
  final Set<int> attendanceIds;
  final Set<int> homeworkIds;
  final Set<int> testIds;
  final Set<int> reprimandIds;
  final Set<int> inboxMessageIds;
  final bool isInboxBaselineKnown;

  ChangeSet diff(SyncSnapshot? previous) {
    if (previous == null) return const ChangeSet();

    final changes = <ChangeItem>[];

    for (final id in markIds.difference(previous.markIds)) {
      changes.add(
        ChangeItem(
          category: ChangeCategory.grades,
          title: t.notification.newGrade,
          entityId: id,
        ),
      );
    }

    for (final id in eventIds.difference(previous.eventIds)) {
      changes.add(
        ChangeItem(
          category: ChangeCategory.schedule,
          title: t.notification.scheduleChange,
          entityId: id,
        ),
      );
    }

    for (final id in attendanceIds.difference(previous.attendanceIds)) {
      changes.add(
        ChangeItem(
          category: ChangeCategory.attendance,
          title: t.notification.attendanceUpdate,
          entityId: id,
        ),
      );
    }

    for (final id in homeworkIds.difference(previous.homeworkIds)) {
      changes.add(
        ChangeItem(
          category: ChangeCategory.homework,
          title: t.notification.newHomework,
          entityId: id,
        ),
      );
    }

    for (final id in testIds.difference(previous.testIds)) {
      changes.add(
        ChangeItem(
          category: ChangeCategory.homework,
          title: t.notification.newTest,
          entityId: id,
        ),
      );
    }

    for (final id in reprimandIds.difference(previous.reprimandIds)) {
      changes.add(
        ChangeItem(
          category: ChangeCategory.notes,
          title: t.notification.newAnnotation,
          entityId: id,
        ),
      );
    }

    if (isInboxBaselineKnown && previous.isInboxBaselineKnown) {
      for (final id in inboxMessageIds.difference(previous.inboxMessageIds)) {
        changes.add(
          ChangeItem(
            category: ChangeCategory.messages,
            title: t.notification.newMessage,
            entityId: id,
          ),
        );
      }
    }

    return ChangeSet(changes: changes);
  }

  Map<String, dynamic> toJson() => {
    'version': currentVersion,
    'markIds': markIds.toList(),
    'eventIds': eventIds.toList(),
    'attendanceIds': attendanceIds.toList(),
    'homeworkIds': homeworkIds.toList(),
    'testIds': testIds.toList(),
    'reprimandIds': reprimandIds.toList(),
    'inboxMessageIds': inboxMessageIds.toList(),
    'isInboxBaselineKnown': isInboxBaselineKnown,
  };

  static Set<int> _intSet(dynamic list) {
    if (list is! List) return {};
    return list.whereType<int>().toSet();
  }

  static const _prefsKey = 'sync_snapshot';
  static const currentVersion = 2;

  static Future<SyncSnapshot?> load(SharedPreferences prefs) async {
    final json = prefs.getString(_prefsKey);
    if (json == null) return null;
    try {
      final map = jsonDecode(json);
      if (map is! Map<String, dynamic>) {
        throw const FormatException('expected a JSON object');
      }
      if (map['version'] != currentVersion) {
        return null;
      }
      return SyncSnapshot.fromJson(map);
    } on FormatException catch (error) {
      debugPrint('SyncSnapshot: sync snapshot unreadable, cleared: $error');
      await prefs.remove(_prefsKey);
      return null;
    }
  }

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setString(_prefsKey, jsonEncode(toJson()));
  }
}
