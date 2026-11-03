import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/domain/child_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChildModeConfig.hidesCategory', () {
    test('hides the category of every section switched off', () {
      const config = ChildModeConfig(
        gradesVisible: false,
        scheduleVisible: false,
        attendanceVisible: false,
        notesVisible: false,
      );

      for (final category in [
        ChangeCategory.grades,
        ChangeCategory.messages,
        ChangeCategory.schedule,
        ChangeCategory.attendance,
        ChangeCategory.notes,
      ]) {
        expect(config.hidesCategory(category), isTrue, reason: '$category');
      }
    });

    test('keeps the category of every section switched on', () {
      const config = ChildModeConfig(messagesVisible: true);

      for (final category in [
        ChangeCategory.grades,
        ChangeCategory.messages,
        ChangeCategory.schedule,
        ChangeCategory.attendance,
        ChangeCategory.notes,
      ]) {
        expect(config.hidesCategory(category), isFalse, reason: '$category');
      }
    });

    test('never hides a category child mode has no switch for', () {
      const config = ChildModeConfig(
        gradesVisible: false,
        scheduleVisible: false,
        attendanceVisible: false,
        notesVisible: false,
      );

      for (final category in [
        ChangeCategory.homework,
        ChangeCategory.tests,
        ChangeCategory.bulletins,
      ]) {
        expect(config.hidesCategory(category), isFalse, reason: '$category');
      }
    });
  });
}
