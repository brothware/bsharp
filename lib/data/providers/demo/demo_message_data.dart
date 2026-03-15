import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/l10n/strings.g.dart';

String _l({required String pl, required String en}) {
  final locale = LocaleSettings.currentLocale;
  return locale == AppLocale.pl ? pl : en;
}

List<PocztaMessage> buildDemoInbox(DateTime now) => [
  PocztaMessage(
    id: 1,
    title: _l(pl: 'Wycieczka klasowa', en: 'Class trip'),
    senderName: 'Anna Nowak',
    sendTime: now.subtract(const Duration(hours: 2)),
    isRead: false,
    isStarred: false,
    content: _l(
      pl: 'Szanowni Państwo, informuję o planowanej wycieczce klasowej do Muzeum Narodowego w dniu 20 marca. Proszę o wyrażenie zgody.',
      en: 'Dear parents, I am informing you about the planned class trip to the National Museum on March 20. Please provide your consent.',
    ),
  ),
  PocztaMessage(
    id: 2,
    title: _l(pl: 'Oceny semestralne', en: 'Semester grades'),
    senderName: 'Marek Kowalczyk',
    sendTime: now.subtract(const Duration(hours: 5)),
    isRead: false,
    isStarred: true,
    content: _l(
      pl: 'Informuję, że oceny semestralne zostały wystawione. Proszę o zapoznanie się z wynikami w dzienniku elektronicznym.',
      en: 'I am informing you that semester grades have been issued. Please review the results in the e-gradebook.',
    ),
  ),
  PocztaMessage(
    id: 3,
    title: _l(pl: 'Konkurs matematyczny', en: 'Maths competition'),
    senderName: 'Anna Nowak',
    sendTime: now.subtract(const Duration(days: 1)),
    isRead: true,
    isStarred: false,
    content: _l(
      pl: 'Jan został zakwalifikowany do etapu szkolnego konkursu matematycznego. Gratulacje!',
      en: 'Jan has been qualified for the school stage of the maths competition. Congratulations!',
    ),
  ),
  PocztaMessage(
    id: 4,
    title: _l(pl: 'Zebranie rodziców', en: 'Parent meeting'),
    senderName: 'Dyrekcja',
    sendTime: now.subtract(const Duration(days: 2)),
    isRead: true,
    isStarred: false,
    content: _l(
      pl: 'Zapraszamy na zebranie rodziców w dniu 15 marca o godz. 17:00.',
      en: 'We invite you to the parent meeting on March 15 at 5:00 PM.',
    ),
  ),
  PocztaMessage(
    id: 5,
    title: _l(pl: 'Zadanie dodatkowe z fizyki', en: 'Extra physics assignment'),
    senderName: 'Tomasz Kamiński',
    sendTime: now.subtract(const Duration(days: 3)),
    isRead: true,
    isStarred: false,
    content: _l(
      pl: 'Dla chętnych: dodatkowe zadania z dynamiki na ocenę celującą.',
      en: 'For volunteers: extra dynamics problems for an excellent grade.',
    ),
  ),
  PocztaMessage(
    id: 6,
    title: _l(pl: 'Ubezpieczenie szkolne', en: 'School insurance'),
    senderName: 'Sekretariat',
    sendTime: now.subtract(const Duration(days: 5)),
    isRead: true,
    isStarred: false,
    content: _l(
      pl: 'Przypominamy o opłaceniu ubezpieczenia szkolnego do końca miesiąca.',
      en: 'Please remember to pay the school insurance by the end of the month.',
    ),
  ),
];

List<PocztaMessage> buildDemoSent(DateTime now) => [
  PocztaMessage(
    id: 101,
    title: _l(pl: 'Re: Wycieczka klasowa', en: 'Re: Class trip'),
    senderName: 'Jan Kowalski',
    sendTime: now.subtract(const Duration(hours: 1)),
    isRead: true,
    isStarred: false,
    content: _l(
      pl: 'Wyrażam zgodę na udział mojego dziecka w wycieczce.',
      en: 'I consent to my child participating in the trip.',
    ),
  ),
  PocztaMessage(
    id: 102,
    title: _l(pl: 'Pytanie o ocenę', en: 'Question about grade'),
    senderName: 'Jan Kowalski',
    sendTime: now.subtract(const Duration(days: 1)),
    isRead: true,
    isStarred: false,
    content: _l(
      pl: 'Czy jest możliwość poprawy oceny ze sprawdzianu?',
      en: 'Is it possible to retake the exam for a better grade?',
    ),
  ),
];

List<PocztaMessage> buildDemoTrash(DateTime now) => [
  PocztaMessage(
    id: 201,
    title: _l(pl: 'Newsletter szkolny', en: 'School newsletter'),
    senderName: 'Sekretariat',
    sendTime: now.subtract(const Duration(days: 10)),
    isRead: true,
    isStarred: false,
    content: _l(
      pl: 'Najnowszy newsletter szkolny.',
      en: 'The latest school newsletter.',
    ),
  ),
];
