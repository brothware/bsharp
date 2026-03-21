module.exports = {
  settings: {
    Settings: [{
      schoolName: 'Ogólnokształcąca Szkoła Muzyczna I i II st. im. Karola Szymanowskiego we Wrocławiu',
      version: '1.6.0',
      protocol: '1.6.0',
      id: 'osm-wroclaw',
      time: '2026-03-20 08:00:00',
      permissions: 255,
    }],
  },

  parentStudents: {
    ParentStudents: [
      { id: 6541, users_edu_id: 9001, name: 'Dawid', surname: 'Śliwa', sex: 'M', phone: null, pin: null },
      { id: 6542, users_edu_id: 9002, name: 'Zofia', surname: 'Kowalczyk', sex: 'K', phone: null, pin: null },
    ],
  },

  fullSync: {
    Students: [
      { action: 'I', id: 6541, users_edu_id: 9001, name: 'Dawid', surname: 'Śliwa', sex: 'M', phone: null, pin: null },
    ],
    Teachers: [
      { action: 'I', id: 201, login: 'akowalska', users_edu_id: 3001, name: 'Anna', surname: 'Kowalska', phone: null, pin: null, user_type: 1 },
      { action: 'I', id: 202, login: 'jnowak', users_edu_id: 3002, name: 'Jan', surname: 'Nowak', phone: null, pin: null, user_type: 1 },
      { action: 'I', id: 203, login: 'mwisniewska', users_edu_id: 3003, name: 'Maria', surname: 'Wiśniewska', phone: null, pin: null, user_type: 1 },
      { action: 'I', id: 204, login: 'pzielinski', users_edu_id: 3004, name: 'Piotr', surname: 'Zieliński', phone: null, pin: null, user_type: 1 },
      { action: 'I', id: 205, login: 'klewandowska', users_edu_id: 3005, name: 'Katarzyna', surname: 'Lewandowska', phone: null, pin: null, user_type: 1 },
    ],
    Subjects: [
      { action: 'I', id: 101, subjects_edu_id: 5001, name: 'Matematyka', abbr: 'Mat' },
      { action: 'I', id: 102, subjects_edu_id: 5002, name: 'Język polski', abbr: 'Pol' },
      { action: 'I', id: 103, subjects_edu_id: 5003, name: 'Język angielski', abbr: 'Ang' },
      { action: 'I', id: 104, subjects_edu_id: 5004, name: 'Fizyka', abbr: 'Fiz' },
      { action: 'I', id: 105, subjects_edu_id: 5005, name: 'Chemia', abbr: 'Che' },
      { action: 'I', id: 106, subjects_edu_id: 5006, name: 'Biologia', abbr: 'Bio' },
      { action: 'I', id: 107, subjects_edu_id: 5007, name: 'Historia', abbr: 'His' },
      { action: 'I', id: 108, subjects_edu_id: 5008, name: 'Geografia', abbr: 'Geo' },
      { action: 'I', id: 109, subjects_edu_id: 5009, name: 'Informatyka', abbr: 'Inf' },
      { action: 'I', id: 110, subjects_edu_id: 5010, name: 'Wychowanie fizyczne', abbr: 'WF' },
    ],
    Terms: [
      { action: 'I', id: 301, parent_id: null, name: '2025/2026', type: 'Y', start_date: '2025-09-01', end_date: '2026-08-31' },
      { action: 'I', id: 302, parent_id: 301, name: 'Semestr I', type: 'S', start_date: '2025-09-01', end_date: '2026-01-31' },
      { action: 'I', id: 303, parent_id: 301, name: 'Semestr II', type: 'S', start_date: '2026-02-01', end_date: '2026-06-30' },
    ],
    Rooms: [
      { action: 'I', id: 501, patrons_id: null, name: '101', description: null },
      { action: 'I', id: 502, patrons_id: null, name: '204', description: null },
      { action: 'I', id: 503, patrons_id: null, name: 'Sala gimnastyczna', description: 'Sala sportowa' },
    ],
    Groups: [
      { action: 'I', id: 401, parent_id: null, groups_edu_id: 7001, name: '8a', type: 'class', attr: null },
    ],
    Events: [
      { action: 'I', id: 1001, name: null, date: '2026-03-20', number: 1, start_time: '08:00', end_time: '08:45', rooms_id: 501, event_types_id: 2001, status: 1, substitution: 0, type: 1, attr: 0, terms_id: 303, lesson_groups_id: null, locked: 0 },
      { action: 'I', id: 1002, name: null, date: '2026-03-20', number: 2, start_time: '08:55', end_time: '09:40', rooms_id: 502, event_types_id: 2002, status: 1, substitution: 0, type: 1, attr: 0, terms_id: 303, lesson_groups_id: null, locked: 0 },
      { action: 'I', id: 1003, name: null, date: '2026-03-20', number: 3, start_time: '09:50', end_time: '10:35', rooms_id: 501, event_types_id: 2003, status: 1, substitution: 0, type: 1, attr: 0, terms_id: 303, lesson_groups_id: null, locked: 0 },
      { action: 'I', id: 1004, name: null, date: '2026-03-20', number: 4, start_time: '10:45', end_time: '11:30', rooms_id: 503, event_types_id: 2004, status: 1, substitution: 0, type: 1, attr: 0, terms_id: 303, lesson_groups_id: null, locked: 0 },
      { action: 'I', id: 1005, name: null, date: '2026-03-20', number: 5, start_time: '11:40', end_time: '12:25', rooms_id: 502, event_types_id: 2005, status: 1, substitution: 0, type: 1, attr: 0, terms_id: 303, lesson_groups_id: null, locked: 0 },
      { action: 'I', id: 1006, name: null, date: '2026-03-21', number: 1, start_time: '08:00', end_time: '08:45', rooms_id: 502, event_types_id: 2002, status: 1, substitution: 0, type: 1, attr: 0, terms_id: 303, lesson_groups_id: null, locked: 0 },
      { action: 'I', id: 1007, name: null, date: '2026-03-21', number: 2, start_time: '08:55', end_time: '09:40', rooms_id: 501, event_types_id: 2006, status: 1, substitution: 0, type: 1, attr: 0, terms_id: 303, lesson_groups_id: null, locked: 0 },
      { action: 'I', id: 1008, name: null, date: '2026-03-21', number: 3, start_time: '09:50', end_time: '10:35', rooms_id: 501, event_types_id: 2007, status: 1, substitution: 0, type: 1, attr: 0, terms_id: 303, lesson_groups_id: null, locked: 0 },
    ],
    EventTypes: [
      { action: 'I', id: 2001, subjects_id: 101, teaching_level: 1, substitution: 0 },
      { action: 'I', id: 2002, subjects_id: 102, teaching_level: 1, substitution: 0 },
      { action: 'I', id: 2003, subjects_id: 103, teaching_level: 1, substitution: 0 },
      { action: 'I', id: 2004, subjects_id: 110, teaching_level: 1, substitution: 0 },
      { action: 'I', id: 2005, subjects_id: 104, teaching_level: 1, substitution: 0 },
      { action: 'I', id: 2006, subjects_id: 107, teaching_level: 1, substitution: 0 },
      { action: 'I', id: 2007, subjects_id: 105, teaching_level: 1, substitution: 0 },
    ],
    EventTypeTeachers: [
      { action: 'I', id: 3001, teachers_id: 201, event_types_id: 2001 },
      { action: 'I', id: 3002, teachers_id: 202, event_types_id: 2002 },
      { action: 'I', id: 3003, teachers_id: 203, event_types_id: 2003 },
      { action: 'I', id: 3004, teachers_id: 205, event_types_id: 2004 },
      { action: 'I', id: 3005, teachers_id: 204, event_types_id: 2005 },
      { action: 'I', id: 3006, teachers_id: 204, event_types_id: 2006 },
      { action: 'I', id: 3007, teachers_id: 203, event_types_id: 2007 },
    ],
    EventTypeTerms: [
      { action: 'I', id: 4001, terms_id: 303, event_types_id: 2001 },
      { action: 'I', id: 4002, terms_id: 303, event_types_id: 2002 },
      { action: 'I', id: 4003, terms_id: 303, event_types_id: 2003 },
      { action: 'I', id: 4004, terms_id: 303, event_types_id: 2004 },
      { action: 'I', id: 4005, terms_id: 303, event_types_id: 2005 },
      { action: 'I', id: 4006, terms_id: 303, event_types_id: 2006 },
      { action: 'I', id: 4007, terms_id: 303, event_types_id: 2007 },
    ],
    EventSubjects: [
      { action: 'I', id: 5001, events_id: 1001, content: 'Równania kwadratowe — powtórzenie', add_time: '2026-03-19 14:00:00' },
      { action: 'I', id: 5002, events_id: 1002, content: 'Lektura: "Pan Tadeusz" — analiza', add_time: '2026-03-19 14:15:00' },
      { action: 'I', id: 5003, events_id: 1003, content: 'Present Perfect vs Past Simple', add_time: '2026-03-19 14:30:00' },
    ],
    EventEvents: [
      { action: 'I', id: 6001, events1_id: 1001, events2_id: 1006 },
    ],
    Marks: [
      { action: 'I', id: 8001, mark_groups_id: 9001, mark_scales_id: 10003, pupil_users_id: 9001, teacher_users_id: 3001, mark_value: 5.0, comments: null, weight: 3, get_date: '2026-03-15', add_time: '2026-03-15 10:00:00', modified: 0, events_id: null },
      { action: 'I', id: 8002, mark_groups_id: 9002, mark_scales_id: 10004, pupil_users_id: 9001, teacher_users_id: 3002, mark_value: 4.0, comments: 'Dobra praca', weight: 2, get_date: '2026-03-17', add_time: '2026-03-17 09:30:00', modified: 0, events_id: null },
      { action: 'I', id: 8003, mark_groups_id: 9003, mark_scales_id: 10005, pupil_users_id: 9001, teacher_users_id: 3003, mark_value: 3.0, comments: null, weight: 1, get_date: '2026-03-18', add_time: '2026-03-18 11:00:00', modified: 0, events_id: null },
      { action: 'I', id: 8004, mark_groups_id: 9004, mark_scales_id: 10002, pupil_users_id: 9001, teacher_users_id: 3004, mark_value: 6.0, comments: 'Doskonała odpowiedź', weight: 2, get_date: '2026-03-19', add_time: '2026-03-19 08:30:00', modified: 0, events_id: null },
    ],
    MarkGroups: [
      { action: 'I', id: 9001, parent_id: null, parent_type: null, mark_group_groups_id: 11001, is_pattern: 0, event_type_terms_id: 4001, mark_kinds_id: 12001, abbreviation: 'Spr', description: 'Sprawdzian', mark_type: 1, mark_format: null, mark_division_groups_id: null, mark_scale_groups_id: 13001, visibility: 1, css_style: null, position: 1, weight: 3, mark_value_range_min: null, mark_value_range_max: null, precision: null, add_by_users_id: null },
      { action: 'I', id: 9002, parent_id: null, parent_type: null, mark_group_groups_id: 11001, is_pattern: 0, event_type_terms_id: 4002, mark_kinds_id: 12002, abbreviation: 'Krt', description: 'Kartkówka', mark_type: 1, mark_format: null, mark_division_groups_id: null, mark_scale_groups_id: 13001, visibility: 1, css_style: null, position: 2, weight: 2, mark_value_range_min: null, mark_value_range_max: null, precision: null, add_by_users_id: null },
      { action: 'I', id: 9003, parent_id: null, parent_type: null, mark_group_groups_id: 11001, is_pattern: 0, event_type_terms_id: 4003, mark_kinds_id: 12003, abbreviation: 'Odp', description: 'Odpowiedź ustna', mark_type: 1, mark_format: null, mark_division_groups_id: null, mark_scale_groups_id: 13001, visibility: 1, css_style: null, position: 3, weight: 1, mark_value_range_min: null, mark_value_range_max: null, precision: null, add_by_users_id: null },
      { action: 'I', id: 9004, parent_id: null, parent_type: null, mark_group_groups_id: 11001, is_pattern: 0, event_type_terms_id: 4005, mark_kinds_id: 12003, abbreviation: 'Odp', description: 'Odpowiedź ustna', mark_type: 1, mark_format: null, mark_division_groups_id: null, mark_scale_groups_id: 13001, visibility: 1, css_style: null, position: 4, weight: 2, mark_value_range_min: null, mark_value_range_max: null, precision: null, add_by_users_id: null },
    ],
    MarkKinds: [
      { action: 'I', id: 12001, parent_id: null, name: 'Sprawdzian', abbreviation: 'Spr', subjects_id: null, public: 1, add_by_users_id: null, default_mark_type: 1, default_mark_scale_groups_id: 13001, default_mark_division_groups_id: null, default_weigth: 3, position: 1, css_style: null },
      { action: 'I', id: 12002, parent_id: null, name: 'Kartkówka', abbreviation: 'Krt', subjects_id: null, public: 1, add_by_users_id: null, default_mark_type: 1, default_mark_scale_groups_id: 13001, default_mark_division_groups_id: null, default_weigth: 2, position: 2, css_style: null },
      { action: 'I', id: 12003, parent_id: null, name: 'Odpowiedź ustna', abbreviation: 'Odp', subjects_id: null, public: 1, add_by_users_id: null, default_mark_type: 1, default_mark_scale_groups_id: 13001, default_mark_division_groups_id: null, default_weigth: 1, position: 3, css_style: null },
    ],
    MarkScales: [
      { action: 'I', id: 10001, mark_scale_groups_id: 13001, abbreviation: '1', name: 'niedostateczny', mark_value: 1.0, image: null, classified: 1, no_count_to_average: 0, css_style: null, mark_scale_edu_id: null },
      { action: 'I', id: 10002, mark_scale_groups_id: 13001, abbreviation: '2', name: 'dopuszczający', mark_value: 2.0, image: null, classified: 1, no_count_to_average: 0, css_style: null, mark_scale_edu_id: null },
      { action: 'I', id: 10003, mark_scale_groups_id: 13001, abbreviation: '3', name: 'dostateczny', mark_value: 3.0, image: null, classified: 1, no_count_to_average: 0, css_style: null, mark_scale_edu_id: null },
      { action: 'I', id: 10004, mark_scale_groups_id: 13001, abbreviation: '4', name: 'dobry', mark_value: 4.0, image: null, classified: 1, no_count_to_average: 0, css_style: null, mark_scale_edu_id: null },
      { action: 'I', id: 10005, mark_scale_groups_id: 13001, abbreviation: '5', name: 'bardzo dobry', mark_value: 5.0, image: null, classified: 1, no_count_to_average: 0, css_style: null, mark_scale_edu_id: null },
      { action: 'I', id: 10006, mark_scale_groups_id: 13001, abbreviation: '6', name: 'celujący', mark_value: 6.0, image: null, classified: 1, no_count_to_average: 0, css_style: null, mark_scale_edu_id: null },
    ],
    MarkGroupGroups: [
      { action: 'I', id: 11001, mark_division_groups_id: null, name: 'Oceny bieżące', parent_id: null, is_pattern: 0, position: 1, weight: 1 },
    ],
    Attendances: [
      { action: 'I', id: 7001, events_id: 1001, students_id: 6541, types_id: 14001 },
      { action: 'I', id: 7002, events_id: 1002, students_id: 6541, types_id: 14001 },
      { action: 'I', id: 7003, events_id: 1003, students_id: 6541, types_id: 14001 },
      { action: 'I', id: 7004, events_id: 1004, students_id: 6541, types_id: 14002 },
      { action: 'I', id: 7005, events_id: 1005, students_id: 6541, types_id: 14003 },
    ],
    AttendanceTypes: [
      { action: 'I', id: 14001, name: 'Obecność', abbr: 'ob', style: 'background-color: #00cc00', count_as: 'P', type: null },
      { action: 'I', id: 14002, name: 'Nieobecność nieusprawiedliwiona', abbr: 'nb', style: 'background-color: #ff0000', count_as: 'A', type: 'N' },
      { action: 'I', id: 14003, name: 'Spóźnienie', abbr: 'sp', style: 'background-color: #ffcc00', count_as: 'L', type: null },
      { action: 'I', id: 14004, name: 'Nieobecność usprawiedliwiona', abbr: 'u', style: 'background-color: #ff9900', count_as: 'A', type: 'E' },
      { action: 'I', id: 14005, name: 'Zwolniony', abbr: 'zw', style: 'background-color: #cccccc', count_as: 'P', type: null },
    ],
  },

  portalViews: {
    users: {
      login: 'dsliwa', name: 'Tomasz', surname: 'Śliwa', messagesToken: 'mock-messages-token-abc123def456',
      pupils: [
        { id: 6541, name: 'Dawid', surname: 'Śliwa', className: '8a' },
        { id: 6542, name: 'Zofia', surname: 'Kowalczyk', className: '8a' },
      ],
    },
    'timetable-events': { items: [
      { id: 1001, dateTimeFrom: '2026-03-20T08:00:00', dateTimeTo: '2026-03-20T08:45:00', subjectName: 'Matematyka', isLocked: false, isCyclic: true, isCanceled: false, substitution: false, teachers: ['Anna Kowalska'], hasTest: false, tests: [], relatedEventsId: [], room: '101', title: null, attendanceLabel: 'ob' },
      { id: 1002, dateTimeFrom: '2026-03-20T08:55:00', dateTimeTo: '2026-03-20T09:40:00', subjectName: 'Język polski', isLocked: false, isCyclic: true, isCanceled: false, substitution: false, teachers: ['Jan Nowak'], hasTest: false, tests: [], relatedEventsId: [], room: '204', title: null, attendanceLabel: 'ob' },
      { id: 1003, dateTimeFrom: '2026-03-20T09:50:00', dateTimeTo: '2026-03-20T10:35:00', subjectName: 'Język angielski', isLocked: false, isCyclic: true, isCanceled: false, substitution: false, teachers: ['Maria Wiśniewska'], hasTest: false, tests: [], relatedEventsId: [], room: '101', title: null, attendanceLabel: 'ob' },
      { id: 1004, dateTimeFrom: '2026-03-20T10:45:00', dateTimeTo: '2026-03-20T11:30:00', subjectName: 'Wychowanie fizyczne', isLocked: false, isCyclic: true, isCanceled: false, substitution: false, teachers: ['Katarzyna Lewandowska'], hasTest: false, tests: [], relatedEventsId: [], room: 'Sala gimnastyczna', title: null, attendanceLabel: 'nb' },
      { id: 1005, dateTimeFrom: '2026-03-20T11:40:00', dateTimeTo: '2026-03-20T12:25:00', subjectName: 'Fizyka', isLocked: false, isCyclic: true, isCanceled: false, substitution: false, teachers: ['Piotr Zieliński'], hasTest: true, tests: [{ id: 15001, title: 'Sprawdzian z optyki' }], relatedEventsId: [], room: '204', title: null, attendanceLabel: 'sp' },
    ]},
    subjects: { items: [
      { id: 101, name: 'Matematyka' }, { id: 102, name: 'Język polski' }, { id: 103, name: 'Język angielski' },
      { id: 104, name: 'Fizyka' }, { id: 105, name: 'Chemia' }, { id: 106, name: 'Biologia' },
      { id: 107, name: 'Historia' }, { id: 108, name: 'Geografia' }, { id: 109, name: 'Informatyka' },
      { id: 110, name: 'Wychowanie fizyczne' },
    ]},
    terms: { items: [
      { id: 301, name: '2025/2026', startDate: '2025-09-01', endDate: '2026-08-31' },
      { id: 302, name: 'Semestr I', startDate: '2025-09-01', endDate: '2026-01-31' },
      { id: 303, name: 'Semestr II', startDate: '2026-02-01', endDate: '2026-06-30' },
    ]},
    marks: { items: [
      { id: 8001, subjectId: 101, kindLabel: 'Sprawdzian', value: '5', markGroupId: 9001, parentMarkGroupId: 0, date: '2026-03-15', weight: 3, bgColor: null, description: 'Równania kwadratowe', comments: null },
      { id: 8002, subjectId: 102, kindLabel: 'Kartkówka', value: '4', markGroupId: 9002, parentMarkGroupId: 0, date: '2026-03-17', weight: 2, bgColor: null, description: 'Analiza wiersza', comments: 'Dobra praca' },
      { id: 8003, subjectId: 103, kindLabel: 'Odpowiedź ustna', value: '3', markGroupId: 9003, parentMarkGroupId: 0, date: '2026-03-18', weight: 1, bgColor: null, description: 'Present Perfect', comments: null },
      { id: 8004, subjectId: 104, kindLabel: 'Odpowiedź ustna', value: '6', markGroupId: 9004, parentMarkGroupId: 0, date: '2026-03-19', weight: 2, bgColor: null, description: 'Optyka geometryczna', comments: 'Doskonała odpowiedź' },
    ]},
    attendances: { percent: 87.5, types: [
      { label: 'Obecność', count: 142 }, { label: 'Nieobecność nieusprawiedliwiona', count: 5 },
      { label: 'Nieobecność usprawiedliwiona', count: 8 }, { label: 'Spóźnienie', count: 3 },
      { label: 'Zwolniony', count: 2 },
    ]},
    homeworks: { items: [
      { id: 16001, subjectName: 'Matematyka', date: '2026-03-18', dueDate: '2026-03-25', content: 'Zad. 1-5 str. 142 — równania kwadratowe z parametrem' },
      { id: 16002, subjectName: 'Język polski', date: '2026-03-19', dueDate: '2026-03-26', content: 'Przeczytać rozdział IV "Pana Tadeusza" i przygotować notatkę' },
      { id: 16003, subjectName: 'Chemia', date: '2026-03-17', dueDate: '2026-03-24', content: 'Ćwiczenie 12 — reakcje utleniania i redukcji' },
    ]},
    tests: { items: [
      { id: 15001, subjectName: 'Fizyka', dateTime: '2026-03-20T11:40:00', title: 'Sprawdzian z optyki', description: 'Optyka geometryczna — odbicie, załamanie światła, soczewki' },
      { id: 15002, subjectName: 'Matematyka', dateTime: '2026-03-27T08:00:00', title: 'Kartkówka z równań kwadratowych', description: null },
      { id: 15003, subjectName: 'Historia', dateTime: '2026-04-03T08:55:00', title: 'Sprawdzian — II Wojna Światowa', description: 'Rozdziały 8-12, mapy, daty' },
    ]},
    reprimands: { items: [
      { id: 17001, date: '2026-03-10', teacherName: 'Anna Kowalska', content: 'Uczeń wykazał się dużą aktywnością na lekcji matematyki', type: 1 },
      { id: 17002, date: '2026-03-15', teacherName: 'Katarzyna Lewandowska', content: 'Brak stroju na lekcji WF', type: 0 },
    ]},
    bulletins: { items: [
      { id: 18001, title: 'Wywiadówka — marzec 2026', dateTime: '2026-03-12 18:00:00', author: 'Dyrekcja', read: '2026-03-12 20:00:00' },
      { id: 18002, title: 'Wycieczka szkolna do Krakowa', dateTime: '2026-03-05 10:00:00', author: 'Jan Nowak', read: null },
      { id: 18003, title: 'Konkurs matematyczny — etap szkolny', dateTime: '2026-02-28 08:00:00', author: 'Anna Kowalska', read: '2026-03-01 07:30:00' },
    ]},
    changelog: { items: [
      { type: 'mark', dateTime: '2026-03-19 08:35:00', subjectName: 'Fizyka', user: 'Piotr Zieliński', newName: '6', newAdditionalInfo: 'Odpowiedź ustna', action: 'add' },
      { type: 'mark', dateTime: '2026-03-17 09:45:00', subjectName: 'Język polski', user: 'Jan Nowak', newName: '4', newAdditionalInfo: 'Kartkówka', action: 'add' },
      { type: 'attendance', dateTime: '2026-03-20 10:50:00', subjectName: 'Wychowanie fizyczne', user: 'Katarzyna Lewandowska', newName: 'nb', newAdditionalInfo: '', action: 'add' },
    ]},
  },

  inbox: [
    { id: 20001, subject: 'Informacja o sprawdzianie z fizyki', date: '2026-03-18T14:30:00', content: 'Szanowni Państwo, informuję że w piątek 20.03 odbędzie się sprawdzian z optyki geometrycznej. Proszę o przypomnienie dzieciom o powtórzeniu materiału.', read_at: '2026-03-18T18:00:00', stared: false, author: { name: 'Piotr Zieliński' }, recipients: [{ name: 'Tomasz Śliwa', roleName: 'Rodzic', read_at: '2026-03-18T18:00:00' }] },
    { id: 20002, subject: 'Wycieczka do Krakowa — zgoda', date: '2026-03-15T10:00:00', content: 'Proszę o podpisanie i dostarczenie zgody na wycieczkę szkolną do Krakowa planowaną na 10-12 kwietnia. Formularz w załączniku.', read_at: null, stared: true, author: { name: 'Jan Nowak' }, recipients: [{ name: 'Tomasz Śliwa', roleName: 'Rodzic', read_at: null }] },
    { id: 20003, subject: 'Zebranie z rodzicami', date: '2026-03-10T08:00:00', content: 'Zapraszam na zebranie z rodzicami w dniu 25.03 o godzinie 17:00 w sali 101.', read_at: '2026-03-10T20:00:00', stared: false, author: { name: 'Anna Kowalska' }, recipients: [{ name: 'Tomasz Śliwa', roleName: 'Rodzic', read_at: '2026-03-10T20:00:00' }] },
  ],

  sent: [
    { id: 21001, subject: 'Re: Wycieczka do Krakowa — zgoda', date: '2026-03-16T09:00:00', content: 'Dziękuję za informację. Zgoda zostanie dostarczona w poniedziałek.', read_at: null, stared: false, author: { name: 'Tomasz Śliwa' }, recipients: [{ name: 'Jan Nowak', roleName: 'Nauczyciel', read_at: '2026-03-16T10:30:00' }] },
  ],

  trash: [
    { id: 22001, subject: 'Stara wiadomość', date: '2026-01-15T12:00:00', content: 'Treść starej wiadomości', read_at: '2026-01-15T14:00:00', stared: false, author: { name: 'System' }, recipients: [{ name: 'Tomasz Śliwa', roleName: 'Rodzic', read_at: '2026-01-15T14:00:00' }] },
  ],

  important: [
    { id: 20002, subject: 'Wycieczka do Krakowa — zgoda', date: '2026-03-15T10:00:00', content: 'Proszę o podpisanie i dostarczenie zgody na wycieczkę szkolną do Krakowa planowaną na 10-12 kwietnia. Formularz w załączniku.', read_at: null, stared: true, author: { name: 'Jan Nowak' }, recipients: [{ name: 'Tomasz Śliwa', roleName: 'Rodzic', read_at: null }] },
  ],

  readMessage: {
    id: 20001, subject: 'Informacja o sprawdzianie z fizyki', date: '2026-03-18T14:30:00',
    content: '<p>Szanowni Państwo,</p><p>Informuję że w piątek 20.03 odbędzie się sprawdzian z optyki geometrycznej obejmujący materiał z rozdziałów 5-7.</p><p>Proszę o przypomnienie dzieciom o powtórzeniu materiału.</p><p>Z poważaniem,<br>Piotr Zieliński</p>',
    read_at: '2026-03-18T18:00:00', stared: false, author: { name: 'Piotr Zieliński' },
    recipients: [{ name: 'Tomasz Śliwa', roleName: 'Rodzic', read_at: '2026-03-18T18:00:00' }], files: [],
  },

  receiverTypes: {
    types: { teachers: 'Nauczyciele', educators: 'Wychowawcy', staff: 'Pracownicy' },
    users: [],
  },

  receivers: [
    { id: 'user_201', name: 'Anna Kowalska', role: 'Nauczyciel' },
    { id: 'user_202', name: 'Jan Nowak', role: 'Nauczyciel' },
    { id: 'user_203', name: 'Maria Wiśniewska', role: 'Nauczyciel' },
    { id: 'user_204', name: 'Piotr Zieliński', role: 'Nauczyciel' },
    { id: 'user_205', name: 'Katarzyna Lewandowska', role: 'Nauczyciel' },
  ],
};

// School B: different school, different student
const schoolBFullSync = {
  Students: [
    { action: 'I', id: 7001, users_edu_id: 9501, name: 'Maja', surname: 'Wiśniewska', sex: 'K', phone: null, pin: null },
  ],
  Teachers: [
    { action: 'I', id: 301, login: 'tnowicki', users_edu_id: 4001, name: 'Tomasz', surname: 'Nowicki', phone: null, pin: null, user_type: 1 },
    { action: 'I', id: 302, login: 'ewojcik', users_edu_id: 4002, name: 'Ewa', surname: 'Wójcik', phone: null, pin: null, user_type: 1 },
  ],
  Subjects: [
    { action: 'I', id: 201, subjects_edu_id: 6001, name: 'Matematyka', abbr: 'Mat' },
    { action: 'I', id: 202, subjects_edu_id: 6002, name: 'Język polski', abbr: 'Pol' },
    { action: 'I', id: 203, subjects_edu_id: 6003, name: 'Biologia', abbr: 'Bio' },
  ],
  Terms: [
    { action: 'I', id: 401, parent_id: null, name: '2025/2026', type: 'Y', start_date: '2025-09-01', end_date: '2026-08-31' },
    { action: 'I', id: 402, parent_id: 401, name: 'Semestr I', type: 'S', start_date: '2025-09-01', end_date: '2026-01-31' },
    { action: 'I', id: 403, parent_id: 401, name: 'Semestr II', type: 'S', start_date: '2026-02-01', end_date: '2026-06-30' },
  ],
  Rooms: [
    { action: 'I', id: 601, patrons_id: null, name: '10', description: null },
  ],
  Groups: [
    { action: 'I', id: 501, parent_id: null, groups_edu_id: 8001, name: '7b', type: 'class', attr: null },
  ],
  Events: [
    { action: 'I', id: 2001, name: null, date: '2026-03-20', number: 1, start_time: '08:00', end_time: '08:45', rooms_id: 601, event_types_id: 3001, status: 1, substitution: 0, type: 1, attr: 0, terms_id: 403, lesson_groups_id: null, locked: 0 },
    { action: 'I', id: 2002, name: null, date: '2026-03-20', number: 2, start_time: '08:55', end_time: '09:40', rooms_id: 601, event_types_id: 3002, status: 1, substitution: 0, type: 1, attr: 0, terms_id: 403, lesson_groups_id: null, locked: 0 },
  ],
  EventTypes: [
    { action: 'I', id: 3001, subjects_id: 201, teaching_level: 1, substitution: 0 },
    { action: 'I', id: 3002, subjects_id: 202, teaching_level: 1, substitution: 0 },
  ],
  EventTypeTeachers: [
    { action: 'I', id: 4001, teachers_id: 301, event_types_id: 3001 },
    { action: 'I', id: 4002, teachers_id: 302, event_types_id: 3002 },
  ],
  EventTypeTerms: [
    { action: 'I', id: 5001, terms_id: 403, event_types_id: 3001 },
    { action: 'I', id: 5002, terms_id: 403, event_types_id: 3002 },
  ],
  EventSubjects: [],
  EventEvents: [],
  Marks: [
    { action: 'I', id: 9001, mark_groups_id: 10001, mark_scales_id: 10004, pupil_users_id: 9501, teacher_users_id: 4001, mark_value: 4.0, comments: null, weight: 3, get_date: '2026-03-16', add_time: '2026-03-16 10:00:00', modified: 0, events_id: null },
    { action: 'I', id: 9002, mark_groups_id: 10002, mark_scales_id: 10005, pupil_users_id: 9501, teacher_users_id: 4002, mark_value: 5.0, comments: 'Świetna praca', weight: 2, get_date: '2026-03-18', add_time: '2026-03-18 09:00:00', modified: 0, events_id: null },
  ],
  MarkGroups: [
    { action: 'I', id: 10001, parent_id: null, parent_type: null, mark_group_groups_id: 11001, is_pattern: 0, event_type_terms_id: 5001, mark_kinds_id: 12001, abbreviation: 'Spr', description: 'Sprawdzian', mark_type: 1, mark_format: null, mark_division_groups_id: null, mark_scale_groups_id: 13001, visibility: 1, css_style: null, position: 1, weight: 3, mark_value_range_min: null, mark_value_range_max: null, precision: null, add_by_users_id: null },
    { action: 'I', id: 10002, parent_id: null, parent_type: null, mark_group_groups_id: 11001, is_pattern: 0, event_type_terms_id: 5002, mark_kinds_id: 12002, abbreviation: 'Krt', description: 'Kartkówka', mark_type: 1, mark_format: null, mark_division_groups_id: null, mark_scale_groups_id: 13001, visibility: 1, css_style: null, position: 2, weight: 2, mark_value_range_min: null, mark_value_range_max: null, precision: null, add_by_users_id: null },
  ],
  MarkKinds: [
    { action: 'I', id: 12001, parent_id: null, name: 'Sprawdzian', abbreviation: 'Spr', subjects_id: null, public: 1, add_by_users_id: null, default_mark_type: 1, default_mark_scale_groups_id: 13001, default_mark_division_groups_id: null, default_weigth: 3, position: 1, css_style: null },
    { action: 'I', id: 12002, parent_id: null, name: 'Kartkówka', abbreviation: 'Krt', subjects_id: null, public: 1, add_by_users_id: null, default_mark_type: 1, default_mark_scale_groups_id: 13001, default_mark_division_groups_id: null, default_weigth: 2, position: 2, css_style: null },
  ],
  MarkScales: [
    { action: 'I', id: 10001, mark_scale_groups_id: 13001, abbreviation: '1', name: 'niedostateczny', mark_value: 1.0, image: null, classified: 1, no_count_to_average: 0, css_style: null, mark_scale_edu_id: null },
    { action: 'I', id: 10002, mark_scale_groups_id: 13001, abbreviation: '2', name: 'dopuszczający', mark_value: 2.0, image: null, classified: 1, no_count_to_average: 0, css_style: null, mark_scale_edu_id: null },
    { action: 'I', id: 10003, mark_scale_groups_id: 13001, abbreviation: '3', name: 'dostateczny', mark_value: 3.0, image: null, classified: 1, no_count_to_average: 0, css_style: null, mark_scale_edu_id: null },
    { action: 'I', id: 10004, mark_scale_groups_id: 13001, abbreviation: '4', name: 'dobry', mark_value: 4.0, image: null, classified: 1, no_count_to_average: 0, css_style: null, mark_scale_edu_id: null },
    { action: 'I', id: 10005, mark_scale_groups_id: 13001, abbreviation: '5', name: 'bardzo dobry', mark_value: 5.0, image: null, classified: 1, no_count_to_average: 0, css_style: null, mark_scale_edu_id: null },
    { action: 'I', id: 10006, mark_scale_groups_id: 13001, abbreviation: '6', name: 'celujący', mark_value: 6.0, image: null, classified: 1, no_count_to_average: 0, css_style: null, mark_scale_edu_id: null },
  ],
  MarkGroupGroups: [
    { action: 'I', id: 11001, mark_division_groups_id: null, name: 'Oceny bieżące', parent_id: null, is_pattern: 0, position: 1, weight: 1 },
  ],
  Attendances: [
    { action: 'I', id: 8001, events_id: 2001, students_id: 7001, types_id: 14001 },
    { action: 'I', id: 8002, events_id: 2002, students_id: 7001, types_id: 14001 },
  ],
  AttendanceTypes: [
    { action: 'I', id: 14001, name: 'Obecność', abbr: 'ob', style: 'background-color: #00cc00', count_as: 'P', type: null },
    { action: 'I', id: 14002, name: 'Nieobecność nieusprawiedliwiona', abbr: 'nb', style: 'background-color: #ff0000', count_as: 'A', type: 'N' },
  ],
};

const schoolBSettings = {
  Settings: [{
    schoolName: 'Szkoła Podstawowa nr 5 w Krakowie',
    version: '1.6.0',
    protocol: '1.6.0',
    id: 'sp5-krakow',
    time: '2026-03-20 08:00:00',
    permissions: 255,
  }],
};

const schoolBParentStudents = {
  ParentStudents: [
    { id: 7001, users_edu_id: 9501, name: 'Maja', surname: 'Wiśniewska', sex: 'K', phone: null, pin: null },
  ],
};

const schoolBInbox = [
  { id: 30001, subject: 'Wyniki konkursu biologicznego', date: '2026-03-19T10:00:00', content: 'Informuję, że Maja zajęła 2. miejsce w konkursie biologicznym.', read_at: null, stared: false, author: { name: 'Ewa Wójcik' }, recipients: [{ name: 'Rodzic', roleName: 'Rodzic', read_at: null }] },
];

module.exports.schoolB = {
  settings: schoolBSettings,
  parentStudents: schoolBParentStudents,
  fullSync: schoolBFullSync,
  inbox: schoolBInbox,
};
