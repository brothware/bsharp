import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/presentation/schedule/widgets/lesson_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ScheduleEntry entry({
    int number = 1,
    String startTime = '08:00:00',
    String endTime = '08:45:00',
    bool isCancelled = false,
    bool isSubstitution = false,
    String? subjectName,
    String? teacherName,
    String? roomName,
    String? topic,
    ScheduleChangeType? changeType,
  }) {
    return ScheduleEntry(
      id: 1,
      date: DateTime(2026, 2, 27),
      number: number,
      startTime: startTime,
      endTime: endTime,
      isCancelled: isCancelled,
      isSubstitution: isSubstitution,
      subjectName: subjectName,
      teacherName: teacherName,
      roomName: roomName,
      topic: topic,
      changeType: changeType,
    );
  }

  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('displays subject name and time range', (tester) async {
    final e = entry(
      subjectName: 'Math',
      teacherName: 'Jan Kowalski',
      roomName: '201',
    );

    await tester.pumpWidget(wrap(LessonCard(entry: e)));

    expect(find.text('Math'), findsOneWidget);
    expect(find.text('08:00 - 08:45'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('shows teacher and room info', (tester) async {
    final e = entry(
      subjectName: 'English',
      teacherName: 'Anna Nowak',
      roomName: '105',
    );

    await tester.pumpWidget(wrap(LessonCard(entry: e)));

    expect(find.text('Anna Nowak • room 105'), findsOneWidget);
  });

  testWidgets('shows topic in italic', (tester) async {
    final e = entry(
      subjectName: 'Physics',
      topic: 'Gravitational force',
    );

    await tester.pumpWidget(wrap(LessonCard(entry: e)));

    expect(find.text('Gravitational force'), findsOneWidget);
  });

  testWidgets('shows cancelled indicator', (tester) async {
    final e = entry(
      subjectName: 'PE',
      isCancelled: true,
      changeType: ScheduleChangeType.cancelled,
    );

    await tester.pumpWidget(wrap(LessonCard(entry: e)));

    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
  });

  testWidgets('shows substitution indicator', (tester) async {
    final e = entry(
      subjectName: 'English',
      isSubstitution: true,
      changeType: ScheduleChangeType.substitution,
    );

    await tester.pumpWidget(wrap(LessonCard(entry: e)));

    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
  });

  testWidgets('triggers onTap callback', (tester) async {
    var tapped = false;
    final e = entry(subjectName: 'Chemistry');

    await tester.pumpWidget(
      wrap(LessonCard(entry: e, onTap: () => tapped = true)),
    );

    await tester.tap(find.byType(LessonCard));
    expect(tapped, isTrue);
  });

  testWidgets('shows default subject name when null', (tester) async {
    final e = entry();

    await tester.pumpWidget(wrap(LessonCard(entry: e)));

    expect(find.text('Lesson'), findsOneWidget);
  });

  testWidgets('shows lesson number', (tester) async {
    final e = entry(
      number: 5,
      subjectName: 'Biology',
    );

    await tester.pumpWidget(wrap(LessonCard(entry: e)));

    expect(find.text('5'), findsOneWidget);
  });
}
