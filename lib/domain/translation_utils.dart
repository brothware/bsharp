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

Map<String, String> _subjectExactMap() => {
  'matematyka': t.subjectNames.matematyka,
  'język polski': t.subjectNames.jezykPolski,
  'język angielski': t.subjectNames.jezykAngielski,
  'język niemiecki': t.subjectNames.jezykNiemiecki,
  'język francuski': t.subjectNames.jezykFrancuski,
  'język hiszpański': t.subjectNames.jezykHiszpanski,
  'język rosyjski': t.subjectNames.jezykRosyjski,
  'język łaciński': t.subjectNames.jezykLacinski,
  'język włoski': t.subjectNames.jezykWloski,
  'język chiński': t.subjectNames.jezykChinski,
  'język portugalski': t.subjectNames.jezykPortugalski,
  'język ukraiński': t.subjectNames.jezykUkrainski,
  'historia': t.subjectNames.historia,
  'historia i teraźniejszość': t.subjectNames.historiaITerazniejszosc,
  'wiedza o społeczeństwie': t.subjectNames.wos,
  'wos': t.subjectNames.wos,
  'geografia': t.subjectNames.geografia,
  'biologia': t.subjectNames.biologia,
  'chemia': t.subjectNames.chemia,
  'fizyka': t.subjectNames.fizyka,
  'informatyka': t.subjectNames.informatyka,
  'technika': t.subjectNames.technika,
  'muzyka': t.subjectNames.muzyka,
  'plastyka': t.subjectNames.plastyka,
  'wychowanie fizyczne': t.subjectNames.wychowanieFizyczne,
  'wf': t.subjectNames.wychowanieFizyczne,
  'edukacja dla bezpieczeństwa': t.subjectNames.edb,
  'edb': t.subjectNames.edb,
  'religia': t.subjectNames.religia,
  'etyka': t.subjectNames.etyka,
  'wychowanie do życia w rodzinie': t.subjectNames.wdz,
  'wdżr': t.subjectNames.wdz,
  'godzina wychowawcza': t.subjectNames.godzinaWychowawcza,
  'zajęcia z wychowawcą': t.subjectNames.zajeciaZWychowawca,
  'przyroda': t.subjectNames.przyroda,
  'filozofia': t.subjectNames.filozofia,
  'wiedza o kulturze': t.subjectNames.wiedzaOKulturze,
  'wiedza o muzyce': t.subjectNames.wiedzaOMuzyce,
  'historia sztuki': t.subjectNames.historiaSztuki,
  'historia muzyki': t.subjectNames.historiaMuzyki,
  'podstawy przedsiębiorczości': t.subjectNames.podstawyPrzedsiebiorczosci,
  'przedsiębiorczość': t.subjectNames.przedsiebiorczosc,
  'edukacja wczesnoszkolna': t.subjectNames.edukacjaWczesnoszkolna,
  'edukacja artystyczna': t.subjectNames.edukacjaArtystyczna,
  'edukacja matematyczna': t.subjectNames.edukacjaMatematyczna,
  'edukacja obywatelska': t.subjectNames.edukacjaObywatelska,
  'edukacja polonistyczna': t.subjectNames.edukacjaPolonistyczna,
  'edukacja ruchowa': t.subjectNames.edukacjaRuchowa,
  'edukacja społ.-przyr.': t.subjectNames.edukacjaSpolPrzyr,
  'edukacja zdrowotna': t.subjectNames.edukacjaZdrowotna,
  'edukacja medialna': t.subjectNames.edukacjaMedialna,
  'zajęcia artystyczne': t.subjectNames.zajeciaArtystyczne,
  'zajęcia techniczne': t.subjectNames.zajeciaTechniczne,
  'zajęcia komputerowe': t.subjectNames.zajeciaKomputerowe,
  'zajęcia logopedyczne': t.subjectNames.zajeciaLogopedyczne,
  'zajęcia op. wych.': t.subjectNames.zajeciaOpWych,
  'zajęcia teatralne/teatr': t.subjectNames.zajeciaTeatralne,
  'zajęcia z pedagogiem szkolnym': t.subjectNames.zajeciaZPedagogiem,
  'zaj. kor. - komp.': t.subjectNames.zajKorKomp,
  'zaj. roz. kom. emoc. i społ.': t.subjectNames.zajRozKomEmocISpo,
  'zachowanie': t.subjectNames.zachowanie,
  'biznes i zarządzanie': t.subjectNames.biznesIZarzadzanie,
  'nauka o muzyce': t.subjectNames.naukaOMuzyce,
  'rewalidacja grupowa': t.subjectNames.rewalidacjaGrupowa,
  'rewalidacja indywidualna': t.subjectNames.rewalidacjaIndywidualna,
  'rezerwacja sali': t.subjectNames.rezerwacjaSali,
  'świetlica': t.subjectNames.swietlica,
  'early stage': t.subjectNames.earlyStage,
  'doradztwo zawodowe': t.subjectNames.doradztwoZawodowe,
  'logopedia': t.subjectNames.logopedia,
  'terapia pedagogiczna': t.subjectNames.terapiaPedagogiczna,
};

Map<String, String> _subjectPrefixMap() => {
  'zespół inst. marching band': t.subjectNames.zespolInstMarchingBand,
  'zespół kam. marching band': t.subjectNames.zespolKamMarchingBand,
  'zespół instr.': t.subjectNames.zespolInstrOrkiestraDeta,
  'zespół instrumentalny': t.subjectNames.zespolInstrumentalny,
  'zespół kameralny': t.subjectNames.zespolKameralny,
  'analiza form muzycznych': t.subjectNames.analizaFormMuzycznych,
  'praca z akompaniatorem': t.subjectNames.pracaZAkompaniatorem,
  'ćwiczenia z kompozycji': t.subjectNames.cwiczeniaZKompozycji,
  'ćwiczenia z harmonii': t.subjectNames.cwiczeniaZHarmonii,
  'improwizacja organowa': t.subjectNames.improwizacjaOrganowa,
  'fortepian obowiązkowy': t.subjectNames.fortepianObowiazkowy,
  'podstawy improwizacji': t.subjectNames.podstawyImprowizacji,
  'czytanie nut głosem': t.subjectNames.czytanieNutGlosem,
  'fortepian dodatkowy': t.subjectNames.fortepianDodatkowy,
  'kształcenie słuchu': t.subjectNames.ksztalcenieSluchu,
  'literatura muzyczna': t.subjectNames.literaturaMuzyczna,
  'gitara elektryczna': t.subjectNames.gitaraElektryczna,
  'gitara klasyczna': t.subjectNames.gitaraKlasyczna,
  'podstawy rytmiki': t.subjectNames.podstawyRytmiki,
  'audycje muzyczne': t.subjectNames.audycjeMuzyczne,
  'formy muzyczne': t.subjectNames.formyMuzyczne,
  'gitara basowa': t.subjectNames.gitaraBasowa,
  'zasady muzyki': t.subjectNames.zasadyMuzyki,
  'emisja głosu': t.subjectNames.emisjaGlosu,
  'flet prosty': t.subjectNames.fletProsty,
  'dyrygentura': t.subjectNames.dyrygentura,
  'wiolonczela': t.subjectNames.wiolonczela,
  'fortepian': t.subjectNames.fortepian,
  'skrzypce': t.subjectNames.skrzypce,
  'kontrabas': t.subjectNames.kontrabas,
  'klawesyn': t.subjectNames.klawesyn,
  'perkusja': t.subjectNames.perkusja,
  'saksofon': t.subjectNames.saksofon,
  'waltornia': t.subjectNames.waltornia,
  'akordeon': t.subjectNames.akordeon,
  'altówka': t.subjectNames.altowka,
  'harmonia': t.subjectNames.harmonia,
  'orkiestra': t.subjectNames.orkiestra,
  'rytmika': t.subjectNames.rytmika,
  'klarnet': t.subjectNames.klarnet,
  'gitara': t.subjectNames.gitara,
  'organy': t.subjectNames.organy,
  'trąbka': t.subjectNames.trabka,
  'śpiew': t.subjectNames.spiew,
  'harfa': t.subjectNames.harfa,
  'fagot': t.subjectNames.fagot,
  'puzon': t.subjectNames.puzon,
  'obój': t.subjectNames.oboj,
  'tuba': t.subjectNames.tuba,
  'flet': t.subjectNames.flet,
  'chór': t.subjectNames.chor,
};

String translateSubjectName(String name) {
  final trimmed = name.trim();
  final key = trimmed.toLowerCase();

  final exact = _subjectExactMap()[key];
  if (exact != null) return matchCase(trimmed, exact);

  final prefixes = _subjectPrefixMap();
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
    'semestr': t.termNames.semestr,
    'semestr pierwszy': '${t.termNames.semestr} I',
    'semestr drugi': '${t.termNames.semestr} II',
    'semestr trzeci': '${t.termNames.semestr} III',
    'i semestr': '${t.termNames.semestr} I',
    'ii semestr': '${t.termNames.semestr} II',
    'iii semestr': '${t.termNames.semestr} III',
    'rok szkolny': t.termNames.rokSzkolny,
    'trymestr': t.termNames.trymestr,
    'trymestr pierwszy': '${t.termNames.trymestr} I',
    'trymestr drugi': '${t.termNames.trymestr} II',
    'trymestr trzeci': '${t.termNames.trymestr} III',
    'i trymestr': '${t.termNames.trymestr} I',
    'ii trymestr': '${t.termNames.trymestr} II',
    'iii trymestr': '${t.termNames.trymestr} III',
  });
}

String translateAttendanceAbbr(String abbr) {
  return _lookupWithCase(abbr, {
    'ob': t.attendanceTypes.obecnoscAbbr,
    'o': t.attendanceTypes.obecnoscAbbr,
    'nb': t.attendanceTypes.nieobecnoscAbbr,
    'n': t.attendanceTypes.nieobecnoscAbbr,
    'sp': t.attendanceTypes.spoznienieAbbr,
    's': t.attendanceTypes.spoznienieAbbr,
    'zw': t.attendanceTypes.zwolnionyAbbr,
    'us': t.attendanceTypes.usprawiedliwionyAbbr,
    'nu': t.attendanceTypes.nieusprawiedliwionyAbbr,
  });
}

String translateAttendanceName(String name) {
  final full = _translateSingleAttendanceName(name);
  if (full != name) return full;

  if (name.contains('/')) {
    final parts = name.split('/').map((p) => p.trim()).toList();
    final translated = parts.map(_translateSingleAttendanceName).toList();
    for (var i = 0; i < parts.length; i++) {
      if (translated[i] != parts[i]) return translated.join(' / ');
    }
  }

  return name;
}

String _translateSingleAttendanceName(String name) {
  return _lookupWithCase(name, {
    'obecność': t.attendanceTypes.obecnosc,
    'nieobecność': t.attendanceTypes.nieobecnosc,
    'nieobecność usprawiedliwiona':
        t.attendanceTypes.nieobecnoscUsprawiedliwiona,
    'nieobecność nieusprawiedliwiona':
        t.attendanceTypes.nieobecnoscNieusprawiedliwiona,
    'nieobecność inna': t.attendanceTypes.nieobecnoscInna,
    'spóźnienie': t.attendanceTypes.spoznienie,
    'spóźnienie usprawiedliwione': t.attendanceTypes.spoznienieUsprawiedliwione,
    'spóźnienie nieusprawiedliwione':
        t.attendanceTypes.spoznienieNieusprawiedliwione,
    'zwolniony': t.attendanceTypes.zwolniony,
    'zwolniony z ćwiczenia': t.attendanceTypes.zwolnionyZCwiczenia,
    'konkurs': t.attendanceTypes.konkurs,
    'konkurs ogólnokształcący': t.attendanceTypes.konkursOgolnoksztalcacy,
    'konkurs muzyczny': t.attendanceTypes.konkursMuzyczny,
    'inna obecność': t.attendanceTypes.innaObecnosc,
    'obecność na świetlicy': t.attendanceTypes.obecnoscNaSwietlicy,
    'sprawdzane na innym wydarzeniu':
        t.attendanceTypes.sprawdzaneNaInnymWydarzeniu,
    'brak nut/brak stroju': t.attendanceTypes.brakNutBrakStroju,
    'zgłoszona niedyspozycja': t.attendanceTypes.zgloszonaNiedyspozycja,
    'egzamin muzyczny': t.attendanceTypes.egzaminMuzyczny,
    'egzamin dyplomowy': t.attendanceTypes.egzaminDyplomowy,
    'popis': t.attendanceTypes.popis,
    'warsztaty': t.attendanceTypes.warsztaty,
    'koncert': t.attendanceTypes.koncert,
    'próba orkiestry': t.attendanceTypes.probaOrkiestry,
    'próba chóru': t.attendanceTypes.probaChoru,
    'próby przed konkursem muzycznym': t.attendanceTypes.probyPrzedKonkursem,
    'spotkanie z psychologiem szkolny': t.attendanceTypes.spotkaniePsycholog,
    'spotkanie z psychologiem szkolnym': t.attendanceTypes.spotkaniePsycholog,
    'spotkanie z pedagogiem szkolnym': t.attendanceTypes.spotkaniePedagog,
    'spotkanie z wychowawcą': t.attendanceTypes.spotkanieWychowawca,
    'tok indywidualny': t.attendanceTypes.tokIndywidualny,
    'wolontariat': t.attendanceTypes.wolontariat,
    'indywidualna organizacja nauki':
        t.attendanceTypes.indywidualnaOrganizacjaNauki,
    'pomoc w przygotowaniu imprezy kl': t.attendanceTypes.pomocWPrzygotowaniu,
  });
}

String translateReceiverRole(String role) {
  return _lookupWithCase(role, {
    'nauczyciel': t.receiverRoles.nauczyciel,
    'nauczycielka': t.receiverRoles.nauczyciel,
    'wychowawca': t.receiverRoles.wychowawca,
    'wychowawczyni': t.receiverRoles.wychowawca,
    'dyrektor': t.receiverRoles.dyrektor,
    'pedagog': t.receiverRoles.pedagog,
    'sekretarz': t.receiverRoles.sekretarz,
    'sekretarka': t.receiverRoles.sekretarz,
    'bibliotekarz': t.receiverRoles.bibliotekarz,
    'bibliotekarka': t.receiverRoles.bibliotekarz,
    'psycholog': t.receiverRoles.psycholog,
    'logopeda': t.receiverRoles.logopeda,
    'rodzic': t.receiverRoles.rodzic,
  });
}
