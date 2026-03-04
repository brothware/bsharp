import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('filteredHomeworksProvider', () {
    test('filters upcoming homeworks', () {
      final future = DateTime.now().add(const Duration(days: 5));
      final past = DateTime.now().subtract(const Duration(days: 5));
      final container = ProviderContainer(
        overrides: [
          homeworksProvider.overrideWithBuild(
            (ref, _) => [
              PortalHomework(
                id: 1,
                subjectName: 'Mat',
                date: '2026-01-01',
                dueDate: future.toIso8601String().substring(0, 10),
                content: 'Future',
              ),
              PortalHomework(
                id: 2,
                subjectName: 'Pol',
                date: '2026-01-01',
                dueDate: past.toIso8601String().substring(0, 10),
                content: 'Past',
              ),
            ],
          ),
          homeworkFilterProvider.overrideWithBuild(
            (ref, _) => HomeworkFilter.upcoming,
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(filteredHomeworksProvider);
      expect(result.length, 1);
      expect(result.first.content, 'Future');
    });

    test('filters past homeworks', () {
      final past = DateTime.now().subtract(const Duration(days: 5));
      final container = ProviderContainer(
        overrides: [
          homeworksProvider.overrideWithBuild(
            (ref, _) => [
              PortalHomework(
                id: 1,
                subjectName: 'Mat',
                date: '2026-01-01',
                dueDate: past.toIso8601String().substring(0, 10),
                content: 'Past',
              ),
            ],
          ),
          homeworkFilterProvider.overrideWithBuild(
            (ref, _) => HomeworkFilter.past,
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(filteredHomeworksProvider);
      expect(result.length, 1);
    });

    test('returns all homeworks', () {
      final container = ProviderContainer(
        overrides: [
          homeworksProvider.overrideWithBuild(
            (ref, _) => [
              const PortalHomework(
                id: 1,
                subjectName: 'A',
                date: '2026-01-01',
                dueDate: '2026-06-01',
                content: 'x',
              ),
              const PortalHomework(
                id: 2,
                subjectName: 'B',
                date: '2026-01-01',
                dueDate: '2025-01-01',
                content: 'y',
              ),
            ],
          ),
          homeworkFilterProvider.overrideWithBuild(
            (ref, _) => HomeworkFilter.all,
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(filteredHomeworksProvider);
      expect(result.length, 2);
    });
  });

  group('groupedHomeworksProvider', () {
    test('groups by due date', () {
      final container = ProviderContainer(
        overrides: [
          homeworksProvider.overrideWithBuild(
            (ref, _) => [
              const PortalHomework(
                id: 1,
                subjectName: 'A',
                date: '2026-01-01',
                dueDate: '2026-03-01',
                content: 'x',
              ),
              const PortalHomework(
                id: 2,
                subjectName: 'B',
                date: '2026-01-01',
                dueDate: '2026-03-01',
                content: 'y',
              ),
              const PortalHomework(
                id: 3,
                subjectName: 'C',
                date: '2026-01-01',
                dueDate: '2026-03-02',
                content: 'z',
              ),
            ],
          ),
          homeworkFilterProvider.overrideWithBuild(
            (ref, _) => HomeworkFilter.all,
          ),
        ],
      );
      addTearDown(container.dispose);

      final grouped = container.read(groupedHomeworksProvider);
      expect(grouped.length, 2);
      expect(grouped['2026-03-01']!.length, 2);
      expect(grouped['2026-03-02']!.length, 1);
    });
  });

  group('remarksProvider, praisesProvider, and infoProvider', () {
    test('separates remarks (type 2), praises (type 1), info (type 0)', () {
      final container = ProviderContainer(
        overrides: [
          reprimandsProvider.overrideWithBuild(
            (ref, _) => [
              const PortalReprimand(
                id: 1,
                date: '2026-02-27',
                teacherName: 'Jan',
                content: 'Info',
                type: 0,
              ),
              const PortalReprimand(
                id: 2,
                date: '2026-02-28',
                teacherName: 'Anna',
                content: 'Praise',
                type: 1,
              ),
              const PortalReprimand(
                id: 3,
                date: '2026-02-26',
                teacherName: 'Piotr',
                content: 'Remark',
                type: 2,
              ),
              const PortalReprimand(
                id: 4,
                date: '2026-02-25',
                teacherName: 'Maria',
                content: 'Info2',
                type: 0,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final info = container.read(infoProvider);
      expect(info.length, 2);
      expect(info.every((r) => r.type == 0), isTrue);
      expect(info.first.date, '2026-02-27');

      final praises = container.read(praisesProvider);
      expect(praises.length, 1);
      expect(praises.first.type, 1);

      final remarks = container.read(remarksProvider);
      expect(remarks.length, 1);
      expect(remarks.first.type, 2);
    });
  });

  group('unreadBulletinsCountProvider', () {
    test('counts unread bulletins', () {
      final container = ProviderContainer(
        overrides: [
          bulletinsProvider.overrideWithBuild(
            (ref, _) => [
              const PortalBulletin(
                id: 1,
                title: 'A',
                content: '',
                date: '2026-02-27',
                author: 'Admin',
                isRead: false,
              ),
              const PortalBulletin(
                id: 2,
                title: 'B',
                content: '',
                date: '2026-02-27',
                author: 'Admin',
                isRead: true,
              ),
              const PortalBulletin(
                id: 3,
                title: 'C',
                content: '',
                date: '2026-02-27',
                author: 'Admin',
                isRead: false,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(unreadBulletinsCountProvider), 2);
    });
  });

  group('groupedGradeChangelogProvider', () {
    test('groups grade changelog by date descending', () {
      final container = ProviderContainer(
        overrides: [
          gradeChangelogProvider.overrideWithBuild(
            (ref, _) => [
              const PortalChangelog(
                type: 'mark',
                dateTime: '2026-02-27 10:00:00',
                subjectName: 'Math',
                user: 'Jan Kowalski',
                newName: '5+',
                newAdditionalInfo: 'Test',
                action: 'I',
              ),
              const PortalChangelog(
                type: 'mark',
                dateTime: '2026-02-26 09:00:00',
                subjectName: 'Polish',
                user: 'Anna Nowak',
                newName: '4',
                action: 'U',
              ),
              const PortalChangelog(
                type: 'mark',
                dateTime: '2026-02-27 14:00:00',
                subjectName: 'English',
                user: 'Piotr Zieliński',
                newName: '3',
                action: 'I',
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final grouped = container.read(groupedGradeChangelogProvider);
      expect(grouped.length, 2);
      expect(grouped.keys.first, '2026-02-27');
      expect(grouped['2026-02-27']!.length, 2);
    });
  });

  group('groupedAttendanceChangelogProvider', () {
    test('groups attendance changelog by date descending', () {
      final container = ProviderContainer(
        overrides: [
          attendanceChangelogProvider.overrideWithBuild(
            (ref, _) => [
              const PortalChangelog(
                type: 'attendance',
                dateTime: '2026-02-27 08:00:00',
                subjectName: 'Math',
                user: 'Jan Kowalski',
                newName: 'Present',
                action: 'I',
              ),
              const PortalChangelog(
                type: 'attendance',
                dateTime: '2026-02-26 08:00:00',
                subjectName: 'Polish',
                user: 'Anna Nowak',
                newName: 'Absent',
                action: 'I',
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final grouped = container.read(groupedAttendanceChangelogProvider);
      expect(grouped.length, 2);
      expect(grouped['2026-02-27']!.length, 1);
      expect(grouped['2026-02-26']!.length, 1);
    });
  });

  group('upcomingTestsProvider', () {
    test('filters future tests and sorts by date', () {
      final future1 = DateTime.now().add(const Duration(days: 10));
      final future2 = DateTime.now().add(const Duration(days: 3));
      final past = DateTime.now().subtract(const Duration(days: 5));

      final container = ProviderContainer(
        overrides: [
          testsProvider.overrideWithBuild(
            (ref, _) => [
              PortalTest(
                id: 1,
                subjectName: 'Mat',
                date: future1.toIso8601String().substring(0, 10),
              ),
              PortalTest(
                id: 2,
                subjectName: 'Pol',
                date: past.toIso8601String().substring(0, 10),
              ),
              PortalTest(
                id: 3,
                subjectName: 'Ang',
                date: future2.toIso8601String().substring(0, 10),
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final upcoming = container.read(upcomingTestsProvider);
      expect(upcoming.length, 2);
      expect(upcoming.first.subjectName, 'Ang');
    });
  });
}
