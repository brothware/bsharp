import 'package:bsharp/l10n/strings.g.dart';

final _termPattern = RegExp(r'^(.+?)\s+(\d{4}/\d{4})$');

String matchCase(String original, String translated) {
  if (original.isEmpty || translated.isEmpty) return translated;
  if (original == original.toUpperCase() &&
      original != original.toLowerCase()) {
    return translated.toUpperCase();
  }
  if (original == original.toLowerCase()) {
    return translated.toLowerCase();
  }
  if (original[0] == original[0].toUpperCase()) {
    return translated[0].toUpperCase() + translated.substring(1);
  }
  return translated;
}

String _lookupWithCase(String input, Map<String, String> map) {
  final key = input.toLowerCase().trim();
  final value = map[key];
  if (value == null) return input;
  return matchCase(input.trim(), value);
}

Map<String, String> _subjectDisplayMap() => {
  'mathematics': t.subjectNames.matematyka,
  'polish': t.subjectNames.jezykPolski,
  'english': t.subjectNames.jezykAngielski,
  'german': t.subjectNames.jezykNiemiecki,
  'french': t.subjectNames.jezykFrancuski,
  'spanish': t.subjectNames.jezykHiszpanski,
  'russian': t.subjectNames.jezykRosyjski,
  'latin': t.subjectNames.jezykLacinski,
  'italian': t.subjectNames.jezykWloski,
  'chinese': t.subjectNames.jezykChinski,
  'portuguese': t.subjectNames.jezykPortugalski,
  'ukrainian': t.subjectNames.jezykUkrainski,
  'history': t.subjectNames.historia,
  'history and the present': t.subjectNames.historiaITerazniejszosc,
  'civic education': t.subjectNames.wos,
  'geography': t.subjectNames.geografia,
  'biology': t.subjectNames.biologia,
  'chemistry': t.subjectNames.chemia,
  'physics': t.subjectNames.fizyka,
  'computer science': t.subjectNames.informatyka,
  'technology': t.subjectNames.technika,
  'music': t.subjectNames.muzyka,
  'art': t.subjectNames.plastyka,
  'physical education': t.subjectNames.wychowanieFizyczne,
  'safety education': t.subjectNames.edb,
  'religion': t.subjectNames.religia,
  'ethics': t.subjectNames.etyka,
  'family life education': t.subjectNames.wdz,
  'homeroom': t.subjectNames.godzinaWychowawcza,
  'nature': t.subjectNames.przyroda,
  'philosophy': t.subjectNames.filozofia,
  'cultural studies': t.subjectNames.wiedzaOKulturze,
  'music knowledge': t.subjectNames.wiedzaOMuzyce,
  'art history': t.subjectNames.historiaSztuki,
  'music history': t.subjectNames.historiaMuzyki,
  'entrepreneurship': t.subjectNames.podstawyPrzedsiebiorczosci,
  'early education': t.subjectNames.edukacjaWczesnoszkolna,
  'art education': t.subjectNames.edukacjaArtystyczna,
  'mathematics education': t.subjectNames.edukacjaMatematyczna,
  'polish language education': t.subjectNames.edukacjaPolonistyczna,
  'movement education': t.subjectNames.edukacjaRuchowa,
  'social-natural education': t.subjectNames.edukacjaSpolPrzyr,
  'health education': t.subjectNames.edukacjaZdrowotna,
  'media education': t.subjectNames.edukacjaMedialna,
  'art class': t.subjectNames.zajeciaArtystyczne,
  'technical class': t.subjectNames.zajeciaTechniczne,
  'computer class': t.subjectNames.zajeciaKomputerowe,
  'speech therapy class': t.subjectNames.zajeciaLogopedyczne,
  'educational care class': t.subjectNames.zajeciaOpWych,
  'theatre class': t.subjectNames.zajeciaTeatralne,
  'class with school counsellor': t.subjectNames.zajeciaZPedagogiem,
  'remedial class — computer': t.subjectNames.zajKorKomp,
  'emotional and social skills': t.subjectNames.zajRozKomEmocISpo,
  'behaviour': t.subjectNames.zachowanie,
  'business and management': t.subjectNames.biznesIZarzadzanie,
  'music studies': t.subjectNames.naukaOMuzyce,
  'group rehabilitation': t.subjectNames.rewalidacjaGrupowa,
  'individual rehabilitation': t.subjectNames.rewalidacjaIndywidualna,
  'room reservation': t.subjectNames.rezerwacjaSali,
  'after-school care': t.subjectNames.swietlica,
  'early stage': t.subjectNames.earlyStage,
  'career counselling': t.subjectNames.doradztwoZawodowe,
  'speech therapy': t.subjectNames.logopedia,
  'pedagogical therapy': t.subjectNames.terapiaPedagogiczna,
  'piano': t.subjectNames.fortepian,
  'violin': t.subjectNames.skrzypce,
  'viola': t.subjectNames.altowka,
  'cello': t.subjectNames.wiolonczela,
  'double bass': t.subjectNames.kontrabas,
  'guitar': t.subjectNames.gitara,
  'classical guitar': t.subjectNames.gitaraKlasyczna,
  'electric guitar': t.subjectNames.gitaraElektryczna,
  'bass guitar': t.subjectNames.gitaraBasowa,
  'flute': t.subjectNames.flet,
  'recorder': t.subjectNames.fletProsty,
  'clarinet': t.subjectNames.klarnet,
  'oboe': t.subjectNames.oboj,
  'bassoon': t.subjectNames.fagot,
  'trumpet': t.subjectNames.trabka,
  'trombone': t.subjectNames.puzon,
  'french horn': t.subjectNames.waltornia,
  'tuba': t.subjectNames.tuba,
  'saxophone': t.subjectNames.saksofon,
  'percussion': t.subjectNames.perkusja,
  'accordion': t.subjectNames.akordeon,
  'organ': t.subjectNames.organy,
  'harp': t.subjectNames.harfa,
  'vocal': t.subjectNames.spiew,
  'harpsichord': t.subjectNames.klawesyn,
  'ear training': t.subjectNames.ksztalcenieSluchu,
  'rhythmics': t.subjectNames.rytmika,
  'chamber ensemble': t.subjectNames.zespolKameralny,
  'orchestra': t.subjectNames.orkiestra,
  'choir': t.subjectNames.chor,
  'music listening': t.subjectNames.audycjeMuzyczne,
  'music theory': t.subjectNames.zasadyMuzyki,
  'harmony': t.subjectNames.harmonia,
  'music literature': t.subjectNames.literaturaMuzyczna,
  'musical forms': t.subjectNames.formyMuzyczne,
  'analysis of musical forms': t.subjectNames.analizaFormMuzycznych,
  'voice projection': t.subjectNames.emisjaGlosu,
  'conducting': t.subjectNames.dyrygentura,
  'sight-singing': t.subjectNames.czytanieNutGlosem,
  'basics of rhythmics': t.subjectNames.podstawyRytmiki,
  'basics of improvisation': t.subjectNames.podstawyImprowizacji,
  'organ improvisation': t.subjectNames.improwizacjaOrganowa,
  'mandatory piano': t.subjectNames.fortepianObowiazkowy,
  'additional piano': t.subjectNames.fortepianDodatkowy,
  'work with accompanist': t.subjectNames.pracaZAkompaniatorem,
  'composition exercises': t.subjectNames.cwiczeniaZKompozycji,
  'harmony exercises': t.subjectNames.cwiczeniaZHarmonii,
  'instrumental ensemble': t.subjectNames.zespolInstrumentalny,
  'instrumental ens. wind orchestra': t.subjectNames.zespolInstrOrkiestraDeta,
  'instrumental ens. marching band': t.subjectNames.zespolInstMarchingBand,
  'chamber ens. marching band': t.subjectNames.zespolKamMarchingBand,
};

String translateSubjectName(String name) {
  final trimmed = name.trim();
  final key = trimmed.toLowerCase();

  final exact = _subjectDisplayMap()[key];
  if (exact != null) return matchCase(trimmed, exact);

  final prefixes = _subjectDisplayMap();
  for (final entry in prefixes.entries) {
    if (key.startsWith(entry.key)) {
      final matchedPart = trimmed.substring(0, entry.key.length);
      final translated = matchCase(matchedPart, entry.value);
      final suffix = trimmed.substring(entry.key.length).trim();
      if (suffix.isEmpty) return translated;
      return '$translated $suffix';
    }
  }

  return name;
}

String translateTermName(String name) {
  final trimmed = name.trim();
  final match = _termPattern.firstMatch(trimmed);
  if (match != null) {
    final label = _translateTermLabel(match.group(1)!.trim());
    return '$label ${match.group(2)}';
  }
  return _translateTermLabel(trimmed);
}

String _translateTermLabel(String label) {
  return _lookupWithCase(label, {
    'semester': t.termNames.semestr,
    'semester i': '${t.termNames.semestr} I',
    'semester ii': '${t.termNames.semestr} II',
    'semester iii': '${t.termNames.semestr} III',
    'school year': t.termNames.rokSzkolny,
    'trimester': t.termNames.trymestr,
    'trimester i': '${t.termNames.trymestr} I',
    'trimester ii': '${t.termNames.trymestr} II',
    'trimester iii': '${t.termNames.trymestr} III',
  });
}

String translateAttendanceAbbr(String abbr) {
  return _lookupWithCase(abbr, {
    'p': t.attendanceTypes.obecnoscAbbr,
    'a': t.attendanceTypes.nieobecnoscAbbr,
    'l': t.attendanceTypes.spoznienieAbbr,
    'r': t.attendanceTypes.zwolnionyAbbr,
    'e': t.attendanceTypes.usprawiedliwionyAbbr,
    'u': t.attendanceTypes.nieusprawiedliwionyAbbr,
  });
}

String translateAttendanceName(String name) {
  return _lookupWithCase(name, {
    'present': t.attendanceTypes.obecnosc,
    'absent': t.attendanceTypes.nieobecnosc,
    'excused absence': t.attendanceTypes.nieobecnoscUsprawiedliwiona,
    'unexcused absence': t.attendanceTypes.nieobecnoscNieusprawiedliwiona,
    'other absence': t.attendanceTypes.nieobecnoscInna,
    'late': t.attendanceTypes.spoznienie,
    'excused late': t.attendanceTypes.spoznienieUsprawiedliwione,
    'unexcused late': t.attendanceTypes.spoznienieNieusprawiedliwione,
    'released': t.attendanceTypes.zwolniony,
    'released from exercise': t.attendanceTypes.zwolnionyZCwiczenia,
    'competition': t.attendanceTypes.konkurs,
    'academic competition': t.attendanceTypes.konkursOgolnoksztalcacy,
    'music competition': t.attendanceTypes.konkursMuzyczny,
    'other presence': t.attendanceTypes.innaObecnosc,
    'present in dayroom': t.attendanceTypes.obecnoscNaSwietlicy,
    'checked at other event': t.attendanceTypes.sprawdzaneNaInnymWydarzeniu,
    'missing sheet music/outfit': t.attendanceTypes.brakNutBrakStroju,
    'reported indisposition': t.attendanceTypes.zgloszonaNiedyspozycja,
    'music exam': t.attendanceTypes.egzaminMuzyczny,
    'diploma exam': t.attendanceTypes.egzaminDyplomowy,
    'recital': t.attendanceTypes.popis,
    'workshop': t.attendanceTypes.warsztaty,
    'concert': t.attendanceTypes.koncert,
    'orchestra rehearsal': t.attendanceTypes.probaOrkiestry,
    'choir rehearsal': t.attendanceTypes.probaChoru,
    'pre-competition rehearsal': t.attendanceTypes.probyPrzedKonkursem,
    'meeting with psychologist': t.attendanceTypes.spotkaniePsycholog,
    'meeting with counsellor': t.attendanceTypes.spotkaniePedagog,
    'meeting with homeroom teacher': t.attendanceTypes.spotkanieWychowawca,
    'individual course': t.attendanceTypes.tokIndywidualny,
    'volunteering': t.attendanceTypes.wolontariat,
    'individual study plan': t.attendanceTypes.indywidualnaOrganizacjaNauki,
    'helping prepare school event': t.attendanceTypes.pomocWPrzygotowaniu,
  });
}

String translateReceiverRole(String role) {
  return _lookupWithCase(role, {
    'teacher': t.receiverRoles.nauczyciel,
    'homeroom teacher': t.receiverRoles.wychowawca,
    'principal': t.receiverRoles.dyrektor,
    'school counsellor': t.receiverRoles.pedagog,
    'secretary': t.receiverRoles.sekretarz,
    'librarian': t.receiverRoles.bibliotekarz,
    'psychologist': t.receiverRoles.psycholog,
    'speech therapist': t.receiverRoles.logopeda,
    'parent': t.receiverRoles.rodzic,
  });
}

String translateGradeName(String name) {
  final trimmed = name.trim();
  final key = trimmed.toLowerCase();
  final map = <String, String>{
    'excellent': t.gradeNames.celujacy,
    'excellent minus': t.gradeNames.celujacyMinus,
    'very good plus': t.gradeNames.bardzoDobryPlus,
    'very good': t.gradeNames.bardzoDobry,
    'very good minus': t.gradeNames.bardzoDobryMinus,
    'good plus': t.gradeNames.dobryPlus,
    'good': t.gradeNames.dobry,
    'good minus': t.gradeNames.dobryMinus,
    'satisfactory plus': t.gradeNames.dostatecznyPlus,
    'satisfactory': t.gradeNames.dostateczny,
    'satisfactory minus': t.gradeNames.dostatecznyMinus,
    'acceptable plus': t.gradeNames.dopuszczajacyPlus,
    'acceptable': t.gradeNames.dopuszczajacy,
    'acceptable minus': t.gradeNames.dopuszczajacyMinus,
    'unsatisfactory plus': t.gradeNames.niedostatecznyPlus,
    'unsatisfactory': t.gradeNames.niedostateczny,
    'unclassified': t.gradeNames.nieklasyfikowany,
    'exempt': t.gradeNames.zwolniony,
    'six': t.gradeNames.szostka,
    'five plus': t.gradeNames.piatkaPlus,
    'five': t.gradeNames.piatka,
    'five minus': t.gradeNames.piatkaMinus,
    'four plus': t.gradeNames.czworkaPlus,
    'four': t.gradeNames.czworka,
    'four minus': t.gradeNames.czworkaMinus,
    'three plus': t.gradeNames.trojkaPlus,
    'three': t.gradeNames.trojka,
    'three minus': t.gradeNames.trojkaMinus,
    'two plus': t.gradeNames.dwojkaPlus,
    'two': t.gradeNames.dwojka,
    'two minus': t.gradeNames.dwojkaMinus,
    'one plus': t.gradeNames.jedynkaPlus,
    'one': t.gradeNames.jedynka,
    'wonderful': t.gradeNames.wspaniale,
    'very well': t.gradeNames.bardzoDobrze,
    'well': t.gradeNames.dobrze,
    'correctly': t.gradeNames.poprawnie,
    'poorly': t.gradeNames.slabo,
    'brilliantly': t.gradeNames.znakomicie,
    'outstandingly': t.gradeNames.celujaco,
    'exceptionally': t.gradeNames.wybitnie,
    'satisfactorily': t.gradeNames.zadowalajaco,
    'averagely': t.gradeNames.przecietnie,
    'unsatisfactorily': t.gradeNames.niezadowalajaco,
    'inappropriately': t.gradeNames.nieodpowiednio,
    'exemplary': t.gradeNames.wzorowe,
    'correct': t.gradeNames.poprawne,
    'inappropriate': t.gradeNames.nieodpowiednie,
    'reprehensible': t.gradeNames.naganne,
    'absent': t.gradeNames.nieobecny,
    'missing assignment': t.gradeNames.brakZadania,
    'unprepared': t.gradeNames.nieprzygotowany,
  };
  final value = map[key];
  if (value == null) return name;
  return matchCase(trimmed, value);
}

String translateGradeCategory(String name) {
  final trimmed = name.trim();
  final key = trimmed.toLowerCase();
  final map = <String, String>{
    'exam': t.gradeCategories.sprawdzian,
    'quiz': t.gradeCategories.kartkowka,
    'oral answer': t.gradeCategories.odpowiedzUstna,
    'homework': t.gradeCategories.pracaDomowa,
    'activity': t.gradeCategories.aktywnosc,
    'project': t.gradeCategories.projekt,
    'essay': t.gradeCategories.wypracowanie,
    'dictation': t.gradeCategories.dyktando,
    'presentation': t.gradeCategories.referat,
    'class work': t.gradeCategories.pracaKlasowa,
    'assignment': t.gradeCategories.zadanie,
    'test': t.gradeCategories.test,
    'exercise': t.gradeCategories.cwiczenie,
    'recitation': t.gradeCategories.recytacja,
    'reading': t.gradeCategories.czytanie,
    'behaviour': t.gradeCategories.zachowanie,
  };
  final value = map[key];
  if (value == null) return name;
  return matchCase(trimmed, value);
}

Map<String, int> gradeDistribution(List<double?> effectiveValues) {
  final dist = <String, int>{};
  for (final v in effectiveValues) {
    if (v == null) continue;
    final key = v.round().toString();
    dist[key] = (dist[key] ?? 0) + 1;
  }
  return dist;
}
