import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/domain/entities/teacher.dart';
import 'package:bsharp/l10n/strings.g.dart';

String _l({required String pl, required String en}) {
  final locale = LocaleSettings.currentLocale;
  return locale == AppLocale.pl ? pl : en;
}

String _date(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

List<PortalHomework> buildDemoHomeworks(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return [
    PortalHomework(
      id: 1,
      subjectName: 'Matematyka',
      date: _date(today.subtract(const Duration(days: 2))),
      dueDate: _date(today.add(const Duration(days: 1))),
      content: _l(
        pl: 'Zadania 1-10 ze strony 95',
        en: 'Exercises 1-10 from page 95',
      ),
    ),
    PortalHomework(
      id: 2,
      subjectName: 'Język polski',
      date: _date(today.subtract(const Duration(days: 1))),
      dueDate: _date(today.add(const Duration(days: 3))),
      content: _l(
        pl: 'Napisz rozprawkę na temat "Czy warto czytać książki?"',
        en: 'Write an essay on "Is it worth reading books?"',
      ),
    ),
    PortalHomework(
      id: 3,
      subjectName: 'Język angielski',
      date: _date(today),
      dueDate: _date(today.add(const Duration(days: 5))),
      content: _l(
        pl: 'Ćwiczenia z unit 5, strony 48-49',
        en: 'Unit 5 exercises, pages 48-49',
      ),
    ),
    PortalHomework(
      id: 4,
      subjectName: 'Fizyka',
      date: _date(today.subtract(const Duration(days: 7))),
      dueDate: _date(today.subtract(const Duration(days: 2))),
      content: _l(
        pl: 'Zadania z dynamiki — zestaw nr 3',
        en: 'Dynamics problem set #3',
      ),
    ),
  ];
}

List<PortalTest> buildDemoTests(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return [
    PortalTest(
      id: 1,
      subjectName: 'Matematyka',
      date: _date(today.add(const Duration(days: 2))),
      title: _l(pl: 'Funkcje kwadratowe', en: 'Quadratic functions'),
    ),
    PortalTest(
      id: 2,
      subjectName: 'Historia',
      date: _date(today.add(const Duration(days: 4))),
      title: _l(pl: 'II wojna światowa', en: 'World War II'),
    ),
    PortalTest(
      id: 3,
      subjectName: 'Chemia',
      date: _date(today.add(const Duration(days: 6))),
      title: _l(pl: 'Reakcje chemiczne', en: 'Chemical reactions'),
    ),
  ];
}

List<PortalReprimand> buildDemoReprimands(
  DateTime now,
  List<Teacher> teachers,
) {
  final today = DateTime(now.year, now.month, now.day);
  return [
    PortalReprimand(
      id: 1,
      date: _date(today.subtract(const Duration(days: 5))),
      teacherName: '${teachers[0].name} ${teachers[0].surname}',
      content: _l(
        pl: 'Wzorowe zachowanie podczas wycieczki szkolnej',
        en: 'Exemplary behaviour during school trip',
      ),
      type: 1,
    ),
    PortalReprimand(
      id: 2,
      date: _date(today.subtract(const Duration(days: 10))),
      teacherName: '${teachers[1].name} ${teachers[1].surname}',
      content: _l(pl: 'Rozmowa podczas lekcji', en: 'Talking during class'),
      type: 2,
    ),
    PortalReprimand(
      id: 3,
      date: _date(today.subtract(const Duration(days: 15))),
      teacherName: '${teachers[2].name} ${teachers[2].surname}',
      content: _l(
        pl: 'Udział w konkursie matematycznym — reprezentowanie szkoły',
        en: 'Participation in maths competition — representing school',
      ),
      type: 0,
    ),
  ];
}

List<PortalBulletin> buildDemoBulletins(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return [
    PortalBulletin(
      id: 1,
      title: _l(
        pl: 'Wywiadówka — 15 marca',
        en: 'Parent-teacher meeting — March 15',
      ),
      content: '',
      date: _date(today.subtract(const Duration(days: 3))),
      author: 'Dyrekcja',
      isRead: true,
    ),
    PortalBulletin(
      id: 2,
      title: _l(pl: 'Dni wolne od zajęć — Wielkanoc', en: 'Easter holidays'),
      content: '',
      date: _date(today.subtract(const Duration(days: 1))),
      author: 'Dyrekcja',
      isRead: false,
    ),
  ];
}

List<PortalChangelog> buildDemoChangelog(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return [
    PortalChangelog(
      type: 'mark',
      dateTime: today.subtract(const Duration(days: 1)).toIso8601String(),
      subjectName: 'Matematyka',
      user: 'Anna Nowak',
      newName: '5',
      action: 'add',
    ),
    PortalChangelog(
      type: 'mark',
      dateTime: today.subtract(const Duration(days: 2)).toIso8601String(),
      subjectName: 'Język polski',
      user: 'Marek Kowalczyk',
      newName: '4',
      action: 'add',
    ),
    PortalChangelog(
      type: 'mark',
      dateTime: today.subtract(const Duration(days: 3)).toIso8601String(),
      subjectName: 'Fizyka',
      user: 'Tomasz Kamiński',
      newName: '3+',
      newAdditionalInfo: '3',
      action: 'update',
    ),
    PortalChangelog(
      type: 'mark',
      dateTime: today.subtract(const Duration(days: 4)).toIso8601String(),
      subjectName: 'Język angielski',
      user: 'Ewa Wiśniewska',
      newName: '5',
      action: 'add',
    ),
    PortalChangelog(
      type: 'mark',
      dateTime: today.subtract(const Duration(days: 5)).toIso8601String(),
      subjectName: 'Biologia',
      user: 'Joanna Zielińska',
      newName: '4',
      action: 'add',
    ),
  ];
}
