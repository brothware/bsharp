import 'dart:convert';

import 'package:bsharp/data/services/sync_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SyncSnapshot.load', () {
    test('a snapshot from before the switch is ignored', () async {
      SharedPreferences.setMockInitialValues({
        'sync_snapshot': jsonEncode({
          'markIds': [1],
          'attendanceIds': [2],
        }),
      });
      final prefs = await SharedPreferences.getInstance();

      expect(await SyncSnapshot.load(prefs), isNull);
    });

    test('a snapshot saved by this version comes back', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await const SyncSnapshot(markIds: {1}, attendanceIds: {2}).save(prefs);

      final loaded = await SyncSnapshot.load(prefs);

      expect(loaded!.markIds, {1});
      expect(loaded.attendanceIds, {2});
    });
  });

  group('SyncSnapshot.diff', () {
    test('an unknown inbox baseline reports no new mail', () {
      const previous = SyncSnapshot(isInboxBaselineKnown: false);
      const current = SyncSnapshot(inboxMessageIds: {1, 2});

      expect(current.diff(previous).isEmpty, isTrue);
    });

    test('a known inbox baseline reports new mail', () {
      const previous = SyncSnapshot(inboxMessageIds: {1});
      const current = SyncSnapshot(inboxMessageIds: {1, 2});

      expect(current.diff(previous).changes, hasLength(1));
    });

    test('the baseline flag survives a save and load', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await const SyncSnapshot(isInboxBaselineKnown: false).save(prefs);

      expect((await SyncSnapshot.load(prefs))!.isInboxBaselineKnown, isFalse);
    });
  });
}
