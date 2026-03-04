import 'dart:convert';

import 'package:bsharp/data/services/sync_data_parser.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/entities/portal.dart';
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
  });

  factory SyncSnapshot.fromSyncData({
    required SyncData syncData,
    List<PortalHomework> homeworks = const [],
    List<PortalTest> tests = const [],
    List<PortalReprimand> reprimands = const [],
    List<PocztaMessage> inboxMessages = const [],
  }) {
    return SyncSnapshot(
      markIds: syncData.marks.map((m) => m.id).toSet(),
      eventIds: syncData.events.map((e) => e.id).toSet(),
      attendanceIds: syncData.attendances.map((a) => a.id).toSet(),
      homeworkIds: homeworks.map((h) => h.id).toSet(),
      testIds: tests.map((t) => t.id).toSet(),
      reprimandIds: reprimands.map((r) => r.id).toSet(),
      inboxMessageIds: inboxMessages.map((m) => m.id).toSet(),
    );
  }

  factory SyncSnapshot.fromJson(Map<String, dynamic> json) {
    return SyncSnapshot(
      markIds: _intSet(json['markIds']),
      eventIds: _intSet(json['eventIds']),
      attendanceIds: _intSet(json['attendanceIds']),
      homeworkIds: _intSet(json['homeworkIds']),
      testIds: _intSet(json['testIds']),
      reprimandIds: _intSet(json['reprimandIds']),
      inboxMessageIds: _intSet(json['inboxMessageIds']),
    );
  }

  final Set<int> markIds;
  final Set<int> eventIds;
  final Set<int> attendanceIds;
  final Set<int> homeworkIds;
  final Set<int> testIds;
  final Set<int> reprimandIds;
  final Set<int> inboxMessageIds;

  ChangeSet diff(SyncSnapshot? previous) {
    if (previous == null) return const ChangeSet();

    final changes = <ChangeItem>[];

    for (final id in markIds.difference(previous.markIds)) {
      changes.add(
        ChangeItem(
          category: ChangeCategory.grades,
          title: 'New grade',
          entityId: id,
        ),
      );
    }

    for (final id in eventIds.difference(previous.eventIds)) {
      changes.add(
        ChangeItem(
          category: ChangeCategory.schedule,
          title: 'Schedule change',
          entityId: id,
        ),
      );
    }

    for (final id in attendanceIds.difference(previous.attendanceIds)) {
      changes.add(
        ChangeItem(
          category: ChangeCategory.attendance,
          title: 'Attendance update',
          entityId: id,
        ),
      );
    }

    for (final id in homeworkIds.difference(previous.homeworkIds)) {
      changes.add(
        ChangeItem(
          category: ChangeCategory.homework,
          title: 'New homework',
          entityId: id,
        ),
      );
    }

    for (final id in testIds.difference(previous.testIds)) {
      changes.add(
        ChangeItem(
          category: ChangeCategory.homework,
          title: 'New test',
          entityId: id,
        ),
      );
    }

    for (final id in reprimandIds.difference(previous.reprimandIds)) {
      changes.add(
        ChangeItem(
          category: ChangeCategory.notes,
          title: 'New note',
          entityId: id,
        ),
      );
    }

    for (final id in inboxMessageIds.difference(previous.inboxMessageIds)) {
      changes.add(
        ChangeItem(
          category: ChangeCategory.messages,
          title: 'New message',
          entityId: id,
        ),
      );
    }

    return ChangeSet(changes: changes);
  }

  Map<String, dynamic> toJson() => {
    'markIds': markIds.toList(),
    'eventIds': eventIds.toList(),
    'attendanceIds': attendanceIds.toList(),
    'homeworkIds': homeworkIds.toList(),
    'testIds': testIds.toList(),
    'reprimandIds': reprimandIds.toList(),
    'inboxMessageIds': inboxMessageIds.toList(),
  };

  static Set<int> _intSet(dynamic list) {
    if (list is! List) return {};
    return list.whereType<int>().toSet();
  }

  static const _prefsKey = 'sync_snapshot';

  static Future<SyncSnapshot?> load(SharedPreferences prefs) async {
    final json = prefs.getString(_prefsKey);
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return SyncSnapshot.fromJson(map);
    } on Object {
      return null;
    }
  }

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setString(_prefsKey, jsonEncode(toJson()));
  }
}
