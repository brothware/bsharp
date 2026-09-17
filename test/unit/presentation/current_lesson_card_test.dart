import 'package:bsharp/app/providers/dashboard_providers.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/presentation/dashboard/widgets/current_lesson_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final DateTime _pinnedNow = () {
  final today = DateTime.now();
  return DateTime(today.year, today.month, today.day, 10, 45);
}();

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ResolvedEvent event({
    required int id,
    required int number,
    required String startTime,
    required String endTime,
    String? subjectName,
    String? eventName,
    String? roomName,
    bool isCancelled = false,
  }) {
    return ResolvedEvent(
      id: id,
      date: DateTime(_pinnedNow.year, _pinnedNow.month, _pinnedNow.day),
      number: number,
      startTime: startTime,
      endTime: endTime,
      subjectName: subjectName,
      eventName: eventName,
      roomName: roomName,
      isCancelled: isCancelled,
    );
  }

  Widget wrap(List<ResolvedEvent> events) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        minuteTickProvider.overrideWith((ref) => _pinnedNow),
        resolvedEventsProvider.overrideWithBuild((ref, _) => events),
      ],
      child: const MaterialApp(
        home: Scaffold(body: CurrentLessonCard()),
      ),
    );
  }

  ResolvedEvent rehearsal() => event(
    id: 30,
    number: 0,
    startTime: '10:40:00',
    endTime: '13:15:00',
    eventName: 'Próba',
    roomName: 'Aula',
  );

  ResolvedEvent maths({bool isCancelled = false}) => event(
    id: 31,
    number: 4,
    startTime: '10:40:00',
    endTime: '11:25:00',
    subjectName: 'matematyka',
    roomName: '4.11',
    isCancelled: isCancelled,
  );

  testWidgets('shows both overlapping entries joined by "or"', (tester) async {
    await tester.pumpWidget(wrap([rehearsal(), maths()]));
    await tester.pump();

    expect(find.text('Próba'), findsOneWidget);
    expect(find.text('matematyka'), findsOneWidget);
    expect(find.text(t.dashboard.orAlternative), findsOneWidget);
    expect(find.text(t.dashboard.currentLesson), findsOneWidget);
    expect(find.text('-'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('shows no divider for a lone lesson', (tester) async {
    await tester.pumpWidget(wrap([maths()]));
    await tester.pump();

    expect(find.text('matematyka'), findsOneWidget);
    expect(find.text(t.dashboard.orAlternative), findsNothing);
  });

  testWidgets('leaves out a lesson cancelled by the overlap', (tester) async {
    await tester.pumpWidget(wrap([rehearsal(), maths(isCancelled: true)]));
    await tester.pump();

    expect(find.text('Próba'), findsOneWidget);
    expect(find.text('matematyka'), findsNothing);
    expect(find.text(t.dashboard.orAlternative), findsNothing);
  });

  testWidgets('labels both as next before they start', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          minuteTickProvider.overrideWith(
            (ref) => DateTime(
              _pinnedNow.year,
              _pinnedNow.month,
              _pinnedNow.day,
              9,
            ),
          ),
          resolvedEventsProvider.overrideWithBuild(
            (ref, _) => [rehearsal(), maths()],
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CurrentLessonCard()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(t.dashboard.nextLesson), findsOneWidget);
    expect(find.text('Próba'), findsOneWidget);
    expect(find.text('matematyka'), findsOneWidget);
  });
}
