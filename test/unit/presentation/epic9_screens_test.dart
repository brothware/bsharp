import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/presentation/bulletins/screens/bulletins_screen.dart';
import 'package:bsharp/presentation/changelog/screens/changelog_screen.dart';
import 'package:bsharp/presentation/homework/screens/homework_screen.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:bsharp/presentation/notes/screens/notes_screen.dart';
import 'package:bsharp/presentation/tests/screens/tests_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeworkScreen', () {
    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [homeworksProvider.overrideWith((ref) => [])],
          child: const MaterialApp(home: Scaffold(body: HomeworkScreen())),
        ),
      );

      expect(find.text('No homework'), findsOneWidget);
    });

    testWidgets('shows filter segments', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [homeworksProvider.overrideWith((ref) => [])],
          child: const MaterialApp(home: Scaffold(body: HomeworkScreen())),
        ),
      );

      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Past'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('shows homework items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeworksProvider.overrideWith(
              (ref) => [
                const PortalHomework(
                  id: 1,
                  subjectName: 'Math',
                  date: '2026-02-20',
                  dueDate: '2026-12-01',
                  content: 'Exercise 5',
                ),
              ],
            ),
            homeworkFilterProvider.overrideWith((ref) => HomeworkFilter.all),
          ],
          child: const MaterialApp(home: Scaffold(body: HomeworkScreen())),
        ),
      );

      expect(find.text('Math'), findsOneWidget);
      expect(find.text('Exercise 5'), findsOneWidget);
    });
  });

  group('TestsScreen', () {
    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [testsProvider.overrideWith((ref) => [])],
          child: const MaterialApp(home: Scaffold(body: TestsScreen())),
        ),
      );

      expect(find.text('No tests'), findsOneWidget);
    });

    testWidgets('shows test items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testsProvider.overrideWith(
              (ref) => [
                const PortalTest(
                  id: 1,
                  subjectName: 'Physics',
                  date: '2026-03-15',
                  title: 'Kinematics',
                ),
              ],
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: TestsScreen())),
        ),
      );

      expect(find.text('Physics'), findsOneWidget);
      expect(find.text('Kinematics'), findsOneWidget);
    });
  });

  group('NotesScreen', () {
    testWidgets('shows tabs for remarks, praises, and info', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [reprimandsProvider.overrideWith((ref) => [])],
          child: const MaterialApp(home: Scaffold(body: NotesScreen())),
        ),
      );

      expect(find.text('Remarks'), findsOneWidget);
      expect(find.text('Praise'), findsOneWidget);
      expect(find.text('Information'), findsOneWidget);
    });

    testWidgets('shows remark items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reprimandsProvider.overrideWith(
              (ref) => [
                const PortalReprimand(
                  id: 1,
                  date: '2026-02-27',
                  teacherName: 'Jan Kowalski',
                  content: 'Talking in class',
                  type: 2,
                ),
              ],
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: NotesScreen())),
        ),
      );

      expect(find.text('Talking in class'), findsOneWidget);
    });

    testWidgets('shows count badges', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reprimandsProvider.overrideWith(
              (ref) => [
                const PortalReprimand(
                  id: 1,
                  date: '2026-02-27',
                  teacherName: 'Jan',
                  content: 'Remark 1',
                  type: 2,
                ),
                const PortalReprimand(
                  id: 2,
                  date: '2026-02-27',
                  teacherName: 'Anna',
                  content: 'Remark 2',
                  type: 2,
                ),
              ],
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: NotesScreen())),
        ),
      );

      expect(find.text('2'), findsOneWidget);
    });
  });

  group('BulletinsScreen', () {
    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [bulletinsProvider.overrideWith((ref) => [])],
          child: const MaterialApp(home: Scaffold(body: BulletinsScreen())),
        ),
      );

      expect(find.text('No announcements'), findsOneWidget);
    });

    testWidgets('shows bulletin items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bulletinsProvider.overrideWith(
              (ref) => [
                const PortalBulletin(
                  id: 1,
                  title: 'Important announcement',
                  content: 'Content',
                  date: '2026-02-27',
                  author: 'Principal',
                  isRead: false,
                ),
              ],
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: BulletinsScreen())),
        ),
      );

      expect(find.text('Important announcement'), findsOneWidget);
      expect(find.byIcon(Icons.mark_email_unread_outlined), findsOneWidget);
    });

    testWidgets('shows read indicator for read bulletins', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bulletinsProvider.overrideWith(
              (ref) => [
                const PortalBulletin(
                  id: 1,
                  title: 'Read',
                  content: 'Content',
                  date: '2026-02-27',
                  author: 'Admin',
                  isRead: true,
                ),
              ],
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: BulletinsScreen())),
        ),
      );

      expect(find.byIcon(Icons.mark_email_read_outlined), findsOneWidget);
    });
  });

  group('ChangelogScreen', () {
    testWidgets('shows tabs for grades and attendance', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gradeChangelogProvider.overrideWith((ref) => []),
            attendanceChangelogProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(home: Scaffold(body: ChangelogScreen())),
        ),
      );

      expect(find.text('Grades'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
    });

    testWidgets('shows empty state when no grades', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gradeChangelogProvider.overrideWith((ref) => []),
            attendanceChangelogProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(home: Scaffold(body: ChangelogScreen())),
        ),
      );

      expect(find.text('No changes'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows grade changelog entries', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gradeChangelogProvider.overrideWith(
              (ref) => [
                const PortalChangelog(
                  type: 'mark',
                  dateTime: '2026-02-27 10:00:00',
                  subjectName: 'Math',
                  user: 'Jan Kowalski',
                  newName: '5+',
                  newAdditionalInfo: 'Test',
                  action: 'I',
                ),
              ],
            ),
            attendanceChangelogProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(home: Scaffold(body: ChangelogScreen())),
        ),
      );

      expect(find.text('2026-02-27'), findsOneWidget);
      expect(find.textContaining('5+'), findsOneWidget);
      expect(find.textContaining('Math'), findsOneWidget);
    });

    testWidgets('shows action-specific icons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gradeChangelogProvider.overrideWith(
              (ref) => [
                const PortalChangelog(
                  type: 'mark',
                  dateTime: '2026-02-27 10:00:00',
                  subjectName: 'Math',
                  user: 'Jan',
                  newName: '5',
                  action: 'I',
                ),
              ],
            ),
            attendanceChangelogProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(home: Scaffold(body: ChangelogScreen())),
        ),
      );

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });
  });
}
