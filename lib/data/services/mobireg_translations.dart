String matchNormCase(String original, String normalized) {
  if (original.isEmpty || normalized.isEmpty) return normalized;
  if (original == original.toUpperCase() &&
      original != original.toLowerCase()) {
    return normalized.toUpperCase();
  }
  if (original == original.toLowerCase()) {
    return normalized.toLowerCase();
  }
  if (original[0] == original[0].toUpperCase()) {
    return normalized[0].toUpperCase() + normalized.substring(1);
  }
  return normalized;
}

const _subjectExact = <String, String>{
  'matematyka': 'Mathematics',
  'język polski': 'Polish',
  'język angielski': 'English',
  'język niemiecki': 'German',
  'język francuski': 'French',
  'język hiszpański': 'Spanish',
  'język rosyjski': 'Russian',
  'język łaciński': 'Latin',
  'język włoski': 'Italian',
  'język chiński': 'Chinese',
  'język portugalski': 'Portuguese',
  'język ukraiński': 'Ukrainian',
  'historia': 'History',
  'historia i teraźniejszość': 'History and the present',
  'wiedza o społeczeństwie': 'Civic education',
  'wos': 'Civic education',
  'geografia': 'Geography',
  'biologia': 'Biology',
  'chemia': 'Chemistry',
  'fizyka': 'Physics',
  'informatyka': 'Computer science',
  'technika': 'Technology',
  'muzyka': 'Music',
  'plastyka': 'Art',
  'wychowanie fizyczne': 'Physical education',
  'wf': 'Physical education',
  'edukacja dla bezpieczeństwa': 'Safety education',
  'edb': 'Safety education',
  'religia': 'Religion',
  'etyka': 'Ethics',
  'wychowanie do życia w rodzinie': 'Family life education',
  'wdżr': 'Family life education',
  'godzina wychowawcza': 'Homeroom',
  'zajęcia z wychowawcą': 'Homeroom',
  'przyroda': 'Nature',
  'filozofia': 'Philosophy',
  'wiedza o kulturze': 'Cultural studies',
  'wiedza o muzyce': 'Music knowledge',
  'historia sztuki': 'Art history',
  'historia muzyki': 'Music history',
  'podstawy przedsiębiorczości': 'Entrepreneurship',
  'przedsiębiorczość': 'Entrepreneurship',
  'edukacja wczesnoszkolna': 'Early education',
  'edukacja artystyczna': 'Art education',
  'edukacja matematyczna': 'Mathematics education',
  'edukacja obywatelska': 'Civic education',
  'edukacja polonistyczna': 'Polish language education',
  'edukacja ruchowa': 'Movement education',
  'edukacja społ.-przyr.': 'Social-natural education',
  'edukacja zdrowotna': 'Health education',
  'edukacja medialna': 'Media education',
  'zajęcia artystyczne': 'Art class',
  'zajęcia techniczne': 'Technical class',
  'zajęcia komputerowe': 'Computer class',
  'zajęcia logopedyczne': 'Speech therapy class',
  'zajęcia op. wych.': 'Educational care class',
  'zajęcia teatralne/teatr': 'Theatre class',
  'zajęcia z pedagogiem szkolnym': 'Class with school counsellor',
  'zaj. kor. - komp.': 'Remedial class — computer',
  'zaj. roz. kom. emoc. i społ.': 'Emotional and social skills',
  'zachowanie': 'Behaviour',
  'biznes i zarządzanie': 'Business and management',
  'nauka o muzyce': 'Music studies',
  'rewalidacja grupowa': 'Group rehabilitation',
  'rewalidacja indywidualna': 'Individual rehabilitation',
  'rezerwacja sali': 'Room reservation',
  'świetlica': 'After-school care',
  'early stage': 'Early stage',
  'doradztwo zawodowe': 'Career counselling',
  'logopedia': 'Speech therapy',
  'terapia pedagogiczna': 'Pedagogical therapy',
};

const _subjectPrefix = <String, String>{
  'zespół inst. marching band': 'Instrumental ens. Marching Band',
  'zespół kam. marching band': 'Chamber ens. Marching Band',
  'zespół instr.': 'Instrumental ens. wind orchestra',
  'zespół instrumentalny': 'Instrumental ensemble',
  'zespół kameralny': 'Chamber ensemble',
  'analiza form muzycznych': 'Analysis of musical forms',
  'praca z akompaniatorem': 'Work with accompanist',
  'ćwiczenia z kompozycji': 'Composition exercises',
  'ćwiczenia z harmonii': 'Harmony exercises',
  'improwizacja organowa': 'Organ improvisation',
  'fortepian obowiązkowy': 'Mandatory piano',
  'podstawy improwizacji': 'Basics of improvisation',
  'czytanie nut głosem': 'Sight-singing',
  'fortepian dodatkowy': 'Additional piano',
  'kształcenie słuchu': 'Ear training',
  'literatura muzyczna': 'Music literature',
  'gitara elektryczna': 'Electric guitar',
  'gitara klasyczna': 'Classical guitar',
  'podstawy rytmiki': 'Basics of rhythmics',
  'audycje muzyczne': 'Music listening',
  'formy muzyczne': 'Musical forms',
  'gitara basowa': 'Bass guitar',
  'zasady muzyki': 'Music theory',
  'emisja głosu': 'Voice projection',
  'flet prosty': 'Recorder',
  'dyrygentura': 'Conducting',
  'wiolonczela': 'Cello',
  'fortepian': 'Piano',
  'skrzypce': 'Violin',
  'kontrabas': 'Double bass',
  'klawesyn': 'Harpsichord',
  'perkusja': 'Percussion',
  'saksofon': 'Saxophone',
  'waltornia': 'French horn',
  'akordeon': 'Accordion',
  'altówka': 'Viola',
  'harmonia': 'Harmony',
  'orkiestra': 'Orchestra',
  'rytmika': 'Rhythmics',
  'klarnet': 'Clarinet',
  'gitara': 'Guitar',
  'organy': 'Organ',
  'trąbka': 'Trumpet',
  'śpiew': 'Vocal',
  'harfa': 'Harp',
  'fagot': 'Bassoon',
  'puzon': 'Trombone',
  'obój': 'Oboe',
  'tuba': 'Tuba',
  'flet': 'Flute',
  'chór': 'Choir',
};

String normalizeMobiregSubjectName(String name) {
  final trimmed = name.trim();
  final key = trimmed.toLowerCase();

  final exact = _subjectExact[key];
  if (exact != null) return matchNormCase(trimmed, exact);

  for (final entry in _subjectPrefix.entries) {
    if (key.startsWith(entry.key)) {
      final matchedPart = trimmed.substring(0, entry.key.length);
      final translated = matchNormCase(matchedPart, entry.value);
      final suffix = trimmed.substring(entry.key.length).trim();
      if (suffix.isEmpty) return translated;
      return '$translated $suffix';
    }
  }

  return name;
}

const _gradeCategoryMap = <String, String>{
  'sprawdzian': 'Exam',
  'kartkówka': 'Quiz',
  'odpowiedź ustna': 'Oral answer',
  'praca domowa': 'Homework',
  'aktywność': 'Activity',
  'projekt': 'Project',
  'wypracowanie': 'Essay',
  'dyktando': 'Dictation',
  'referat': 'Presentation',
  'praca klasowa': 'Class work',
  'zadanie': 'Assignment',
  'test': 'Test',
  'ćwiczenie': 'Exercise',
  'recytacja': 'Recitation',
  'czytanie': 'Reading',
  'zachowanie': 'Behaviour',
};

String normalizeMobiregGradeCategory(String name) {
  final trimmed = name.trim();
  final key = trimmed.toLowerCase();
  final value = _gradeCategoryMap[key];
  if (value == null) return name;
  return matchNormCase(trimmed, value);
}

const _gradeNameMap = <String, String>{
  'celujący': 'Excellent',
  'celujący z minusem': 'Excellent minus',
  'bardzo dobry z plusem': 'Very good plus',
  'bardzo dobry': 'Very good',
  'bardzo dobry z minusem': 'Very good minus',
  'dobry z plusem': 'Good plus',
  'dobry': 'Good',
  'dobry z minusem': 'Good minus',
  'dostateczny z plusem': 'Satisfactory plus',
  'dostateczny': 'Satisfactory',
  'dostateczny z minusem': 'Satisfactory minus',
  'dopuszczający z plusem': 'Acceptable plus',
  'dopuszczający': 'Acceptable',
  'dopuszczający z minusem': 'Acceptable minus',
  'niedostateczny z plusem': 'Unsatisfactory plus',
  'niedostateczny': 'Unsatisfactory',
  'nieklasyfikowany': 'Unclassified',
  'nieklasyfikowana': 'Unclassified',
  'zwolniony': 'Exempt',
  'zwolniona': 'Exempt',
  'szóstka': 'Six',
  'piątka z plusem': 'Five plus',
  'piątka': 'Five',
  'piątka z minusem': 'Five minus',
  'czwórka z plusem': 'Four plus',
  'czwórka': 'Four',
  'czwórka z minusem': 'Four minus',
  'trójka z plusem': 'Three plus',
  'trójka': 'Three',
  'trójka z minusem': 'Three minus',
  'dwójka z plusem': 'Two plus',
  'dwójka': 'Two',
  'dwójka z minusem': 'Two minus',
  'jedynka z plusem': 'One plus',
  'jedynka': 'One',
  'wspaniale': 'Wonderful',
  'bardzo dobrze': 'Very well',
  'dobrze': 'Well',
  'poprawnie': 'Correctly',
  'słabo': 'Poorly',
  'znakomicie': 'Brilliantly',
  'celująco': 'Outstandingly',
  'wybitnie': 'Exceptionally',
  'zadowalająco': 'Satisfactorily',
  'przeciętnie': 'Averagely',
  'niezadowalająco': 'Unsatisfactorily',
  'nieodpowiednio': 'Inappropriately',
  'wzorowe': 'Exemplary',
  'bardzo dobre': 'Very good',
  'dobre': 'Good',
  'poprawne': 'Correct',
  'nieodpowiednie': 'Inappropriate',
  'naganne': 'Reprehensible',
  'nieobecny': 'Absent',
  'nieobecna': 'Absent',
  'brak zadania': 'Missing assignment',
  'nieprzygotowany': 'Unprepared',
  'nieprzygotowana': 'Unprepared',
};

String normalizeMobiregGradeName(String name) {
  final trimmed = name.trim();
  final key = trimmed.toLowerCase();
  final value = _gradeNameMap[key];
  if (value == null) return name;
  return matchNormCase(trimmed, value);
}

const _attendanceNameMap = <String, String>{
  'obecność': 'Present',
  'nieobecność': 'Absent',
  'nieobecność usprawiedliwiona': 'Excused absence',
  'nieobecność nieusprawiedliwiona': 'Unexcused absence',
  'nieobecność inna': 'Other absence',
  'spóźnienie': 'Late',
  'spóźnienie usprawiedliwione': 'Excused late',
  'spóźnienie nieusprawiedliwione': 'Unexcused late',
  'zwolniony': 'Released',
  'zwolniony z ćwiczenia': 'Released from exercise',
  'konkurs': 'Competition',
  'konkurs ogólnokształcący': 'Academic competition',
  'konkurs muzyczny': 'Music competition',
  'inna obecność': 'Other presence',
  'obecność na świetlicy': 'Present in dayroom',
  'sprawdzane na innym wydarzeniu': 'Checked at other event',
  'brak nut/brak stroju': 'Missing sheet music/outfit',
  'zgłoszona niedyspozycja': 'Reported indisposition',
  'egzamin muzyczny': 'Music exam',
  'egzamin dyplomowy': 'Diploma exam',
  'popis': 'Recital',
  'warsztaty': 'Workshop',
  'koncert': 'Concert',
  'próba orkiestry': 'Orchestra rehearsal',
  'próba chóru': 'Choir rehearsal',
  'próby przed konkursem muzycznym': 'Pre-competition rehearsal',
  'spotkanie z psychologiem szkolny': 'Meeting with psychologist',
  'spotkanie z psychologiem szkolnym': 'Meeting with psychologist',
  'spotkanie z pedagogiem szkolnym': 'Meeting with counsellor',
  'spotkanie z wychowawcą': 'Meeting with homeroom teacher',
  'tok indywidualny': 'Individual course',
  'wolontariat': 'Volunteering',
  'indywidualna organizacja nauki': 'Individual study plan',
  'pomoc w przygotowaniu imprezy kl': 'Helping prepare school event',
};

const _attendanceAbbrMap = <String, String>{
  'ob': 'P',
  'o': 'P',
  'nb': 'A',
  'n': 'A',
  'sp': 'L',
  's': 'L',
  'zw': 'R',
  'us': 'E',
  'nu': 'U',
};

String normalizeMobiregAttendanceName(String name) {
  final trimmed = name.trim();
  final key = trimmed.toLowerCase();

  final full = _attendanceNameMap[key];
  if (full != null) return matchNormCase(trimmed, full);

  if (name.contains('/')) {
    final parts = name.split('/').map((p) => p.trim()).toList();
    final translated = parts.map((p) {
      final v = _attendanceNameMap[p.toLowerCase()];
      return v != null ? matchNormCase(p, v) : p;
    }).toList();
    for (var i = 0; i < parts.length; i++) {
      if (translated[i] != parts[i]) return translated.join(' / ');
    }
  }

  return name;
}

String normalizeMobiregAttendanceAbbr(String abbr) {
  final key = abbr.toLowerCase().trim();
  final value = _attendanceAbbrMap[key];
  if (value == null) return abbr;
  return matchNormCase(abbr.trim(), value);
}

const _receiverRoleMap = <String, String>{
  'nauczyciel': 'Teacher',
  'nauczycielka': 'Teacher',
  'wychowawca': 'Homeroom teacher',
  'wychowawczyni': 'Homeroom teacher',
  'dyrektor': 'Principal',
  'pedagog': 'School counsellor',
  'sekretarz': 'Secretary',
  'sekretarka': 'Secretary',
  'bibliotekarz': 'Librarian',
  'bibliotekarka': 'Librarian',
  'psycholog': 'Psychologist',
  'logopeda': 'Speech therapist',
  'rodzic': 'Parent',
};

String normalizeMobiregReceiverRole(String role) {
  final trimmed = role.trim();
  final key = trimmed.toLowerCase();
  final value = _receiverRoleMap[key];
  if (value == null) return role;
  return matchNormCase(trimmed, value);
}

const _termLabelMap = <String, String>{
  'semestr': 'Semester',
  'semestr pierwszy': 'Semester I',
  'semestr drugi': 'Semester II',
  'semestr trzeci': 'Semester III',
  'i semestr': 'Semester I',
  'ii semestr': 'Semester II',
  'iii semestr': 'Semester III',
  'rok szkolny': 'School year',
  'trymestr': 'Trimester',
  'trymestr pierwszy': 'Trimester I',
  'trymestr drugi': 'Trimester II',
  'trymestr trzeci': 'Trimester III',
  'i trymestr': 'Trimester I',
  'ii trymestr': 'Trimester II',
  'iii trymestr': 'Trimester III',
};

final _termPattern = RegExp(r'^(.+?)\s+(\d{4}/\d{4})$');

String normalizeMobiregTermName(String name) {
  final trimmed = name.trim();
  final match = _termPattern.firstMatch(trimmed);
  if (match != null) {
    final label = _normalizeTermLabel(match.group(1)!.trim());
    return '$label ${match.group(2)}';
  }
  return _normalizeTermLabel(trimmed);
}

String _normalizeTermLabel(String label) {
  final key = label.toLowerCase().trim();
  final value = _termLabelMap[key];
  if (value == null) return label;
  return matchNormCase(label, value);
}
