import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/domain/entities/subject.dart';
import 'package:bsharp/domain/entities/teacher.dart';
import 'package:bsharp/l10n/strings.g.dart';

String _l({required String pl, required String en}) {
  final locale = LocaleSettings.currentLocale;
  return locale == AppLocale.pl ? pl : en;
}

const demoSubjectNames = [
  'Mathematics',
  'Polish',
  'English',
  'Physics',
  'Chemistry',
  'Biology',
  'History',
  'Geography',
  'Computer science',
  'Physical education',
];

const demoTeacherAssignment = [1, 2, 3, 4, 5, 6, 7, 8, 1, 6];

List<ResolvedEvent> buildDemoResolvedEvents(
  DateTime now,
  List<Subject> subjects,
  List<Teacher> teachers,
) {
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final bellTimes = [
    ('08:00', '08:45'),
    ('08:55', '09:40'),
    ('09:50', '10:35'),
    ('10:55', '11:40'),
    ('11:50', '12:35'),
    ('12:45', '13:30'),
    ('13:40', '14:25'),
  ];
  final schedule = <List<int>>[
    [1, 2, 3, 7, 4, 10, 9],
    [2, 1, 5, 6, 3, 8, 10],
    [3, 4, 1, 2, 6, 5, 7],
    [1, 7, 8, 3, 9, 2, 4],
    [2, 3, 1, 10, 5, 6, 8],
  ];
  final rooms = [
    '101',
    '205',
    '112',
    '301',
    '015',
    '101',
    _l(pl: 'Sala gimnastyczna', en: 'Gym'),
  ];

  final topics = <int, String>{
    1: 'Quadratic equations',
    2: 'Poem analysis',
    3: 'Present Perfect Tense',
    4: "Newton's laws of motion",
    9: 'Loops in Python',
  };

  final events = <ResolvedEvent>[];
  var eventId = 1;
  for (var dayIdx = 0; dayIdx < 5; dayIdx++) {
    final date = monday.add(Duration(days: dayIdx));
    final daySchedule = schedule[dayIdx];
    for (var lessonIdx = 0; lessonIdx < daySchedule.length; lessonIdx++) {
      final subjectIdx = daySchedule[lessonIdx] - 1;
      final teacherIdx = demoTeacherAssignment[subjectIdx] - 1;
      final teacher = teachers[teacherIdx];

      final topic = (lessonIdx <= 1) ? topics[subjectIdx + 1] : null;

      events.add(
        ResolvedEvent(
          id: eventId,
          date: DateTime(date.year, date.month, date.day),
          number: lessonIdx + 1,
          startTime: bellTimes[lessonIdx].$1,
          endTime: bellTimes[lessonIdx].$2,
          subjectName: demoSubjectNames[subjectIdx],
          teacherName: '${teacher.name} ${teacher.surname}',
          roomName: rooms[lessonIdx],
          topic: topic,
          subjectId: subjects[subjectIdx].id,
          isLocked: true,
        ),
      );
      eventId++;
    }
  }
  return events;
}
