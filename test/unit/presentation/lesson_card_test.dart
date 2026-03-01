import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/domain/entities/event.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/presentation/schedule/widgets/lesson_card.dart';

void main() {
  Event _event({
    int number = 1,
    String startTime = '08:00:00',
    String endTime = '08:45:00',
    int status = 1,
    int substitution = 0,
  }) {
    return Event(
      id: 1,
      date: DateTime(2026, 2, 27),
      number: number,
      startTime: startTime,
      endTime: endTime,
      eventTypesId: 1,
      status: status,
      substitution: substitution,
      type: 0,
      attr: 0,
      locked: 0,
    );
  }

  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('displays subject name and time range', (tester) async {
    final entry = ScheduleEntry(
      event: _event(startTime: '08:00:00', endTime: '08:45:00'),
      subjectName: 'Math',
      teacherName: 'Jan Kowalski',
      roomName: '201',
    );

    await tester.pumpWidget(wrap(LessonCard(entry: entry)));

    expect(find.text('Math'), findsOneWidget);
    expect(find.text('08:00 - 08:45'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('shows teacher and room info', (tester) async {
    final entry = ScheduleEntry(
      event: _event(),
      subjectName: 'English',
      teacherName: 'Anna Nowak',
      roomName: '105',
    );

    await tester.pumpWidget(wrap(LessonCard(entry: entry)));

    expect(find.text('Anna Nowak • room 105'), findsOneWidget);
  });

  testWidgets('shows topic in italic', (tester) async {
    final entry = ScheduleEntry(
      event: _event(),
      subjectName: 'Physics',
      topic: 'Gravitational force',
    );

    await tester.pumpWidget(wrap(LessonCard(entry: entry)));

    expect(find.text('Gravitational force'), findsOneWidget);
  });

  testWidgets('shows cancelled indicator', (tester) async {
    final entry = ScheduleEntry(
      event: _event(status: 0),
      subjectName: 'PE',
      changeType: ScheduleChangeType.cancelled,
    );

    await tester.pumpWidget(wrap(LessonCard(entry: entry)));

    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
  });

  testWidgets('shows substitution indicator', (tester) async {
    final entry = ScheduleEntry(
      event: _event(substitution: 1),
      subjectName: 'English',
      changeType: ScheduleChangeType.substitution,
    );

    await tester.pumpWidget(wrap(LessonCard(entry: entry)));

    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
  });

  testWidgets('triggers onTap callback', (tester) async {
    var tapped = false;
    final entry = ScheduleEntry(
      event: _event(),
      subjectName: 'Chemistry',
    );

    await tester.pumpWidget(
      wrap(LessonCard(entry: entry, onTap: () => tapped = true)),
    );

    await tester.tap(find.byType(LessonCard));
    expect(tapped, isTrue);
  });

  testWidgets('shows default subject name when null', (tester) async {
    final entry = ScheduleEntry(event: _event());

    await tester.pumpWidget(wrap(LessonCard(entry: entry)));

    expect(find.text('Lesson'), findsOneWidget);
  });

  testWidgets('shows lesson number', (tester) async {
    final entry = ScheduleEntry(
      event: _event(number: 5),
      subjectName: 'Biology',
    );

    await tester.pumpWidget(wrap(LessonCard(entry: entry)));

    expect(find.text('5'), findsOneWidget);
  });
}
