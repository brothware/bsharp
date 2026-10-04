const credentials = { login: 'user', password: 'pass' };

const jwt = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1aWQiOjgyNTYsInN1YiI6InVzZXIiLCJyb2wiOjJ9.mock-signature';

const secondSchool = 'sp5-krakow';

const users = {
    "id": 8256,
    "eduId": 959517,
    "firstname": "Jan",
    "lastname": "Kowalski",
    "role": 2,
    "schoolName": [
      "Ogólnokształcąca Szkoła Muzyczna I i II stopnia",
      "ul. Przykładowa 1 50-044 Wrocław",
      "https://example.test"
    ],
    "pupils": [
      {
        "id": 6339,
        "firstname": "Maria",
        "lastname": "Kowalska"
      }
    ],
    "messagingUrl": "https://poczta.mobireg.pl/sso",
    "messagesToken": "bW9jay1tZXNzYWdlcy10b2tlbg==",
    "appConfig": {
      "modules": {
        "attendances": 1,
        "reprimands": 1,
        "timetable": 1,
        "announcements": 1,
        "notifications": 1,
        "schedule": 1,
        "sms": 1
      },
      "marks": {
        "parentSuggestionMode": 0,
        "showAverage": 0,
        "showDescriptive": 1
      }
    }
  };

const secondSchoolUsers = {
    "id": 9120,
    "eduId": 960210,
    "firstname": "Agnieszka",
    "lastname": "Wiśniewska",
    "role": 2,
    "schoolName": [
      "Ogólnokształcąca Szkoła Muzyczna I i II stopnia",
      "ul. Przykładowa 1 50-044 Wrocław",
      "https://example.test"
    ],
    "pupils": [
      {
        "id": 7001,
        "firstname": "Maja",
        "lastname": "Wiśniewska"
      }
    ],
    "messagingUrl": "https://poczta.mobireg.pl/sso",
    "messagesToken": "bW9jay1tZXNzYWdlcy10b2tlbi1zY2hvb2xi",
    "appConfig": {
      "modules": {
        "attendances": 1,
        "reprimands": 1,
        "timetable": 1,
        "announcements": 1,
        "notifications": 1,
        "schedule": 1,
        "sms": 1
      },
      "marks": {
        "parentSuggestionMode": 0,
        "showAverage": 0,
        "showDescriptive": 1
      }
    }
  };

const appViews = {
  users: (_body, school) => (school === secondSchool ? secondSchoolUsers : users),
  terms: () => ([
    {
      "id": 1,
      "isYear": 1,
      "label": "Rok szkolny 2026/2027",
      "parentId": 0,
      "dateFrom": "2026-09-01",
      "dateTo": "2027-08-31"
    },
    {
      "id": 4,
      "isYear": 0,
      "label": "Semestr I",
      "parentId": 1,
      "dateFrom": "2026-09-01",
      "dateTo": "2027-01-31"
    },
    {
      "id": 7,
      "isYear": 0,
      "label": "Semestr II",
      "parentId": 1,
      "dateFrom": "2027-02-01",
      "dateTo": "2027-08-31"
    }
  ]),
  subjects: () => ([
    {
      "id": 123,
      "label": "chór"
    },
    {
      "id": 54,
      "label": "przyroda"
    },
    {
      "id": 384,
      "label": "edukacja zdrowotna"
    }
  ]),
  marks: (body) => (body.termId === '4' ? {
    "markDescriptives": {
      "zachowanie": "",
      "obowiazkowe": "",
      "zalecenia": ""
    },
    "subjects": [
      {
        "id": 54,
        "label": "przyroda",
        "teachers": [
          {
            "id": 4977,
            "name": "Joanna Nowak"
          }
        ],
        "suggestView": 0,
        "value": "",
        "isFinal": 0,
        "mtTeacherId": 0
      },
      {
        "id": 384,
        "label": "edukacja zdrowotna",
        "teachers": [
          {
            "id": 4938,
            "name": "Anna Nowak"
          }
        ],
        "suggestView": 0,
        "value": "5",
        "isFinal": 1,
        "mtTeacherId": 4938
      }
    ],
    "markGroups": [
      {
        "id": 2200,
        "subjectId": 54,
        "kindLabel": "karty pracy",
        "markGroupId": 2200,
        "parentMarkGroupId": 0,
        "bgColor": "color: #0000FF;",
        "description": "kodeks przyrodnika"
      }
    ],
    "grades": [
      {
        "id": 13414,
        "subjectId": 54,
        "kindLabel": "karty pracy",
        "value": "+",
        "markGroupId": 2200,
        "parentMarkGroupId": 0,
        "date": "2026-10-01",
        "teacherId": 4977,
        "bgColor": "color: #0000FF;",
        "description": "kodeks przyrodnika",
        "comments": ""
      },
      {
        "id": 13415,
        "subjectId": 54,
        "kindLabel": "sprawdzian",
        "value": "4+",
        "markGroupId": 2201,
        "parentMarkGroupId": 0,
        "date": "2026-10-02",
        "teacherId": 4977,
        "bgColor": "color: #000000;",
        "description": "dział 1",
        "comments": "poprawa"
      },
      {
        "id": 4430,
        "subjectId": 384,
        "kindLabel": "Aktywność",
        "value": "5",
        "markGroupId": 1073,
        "parentMarkGroupId": 0,
        "date": "2026-09-19",
        "teacherId": 4938,
        "bgColor": "color: #0000FF;",
        "description": "Aktywność i zaangażowanie na lekcji",
        "comments": ""
      }
    ],
    "teachers": {
      "4938": {
        "first_name": "Anna",
        "surname": "Nowak",
        "id": 4938
      },
      "4977": {
        "first_name": "Joanna",
        "surname": "Nowak",
        "id": 4977
      }
    }
  } : {
    "markDescriptives": {
      "zachowanie": "",
      "obowiazkowe": "",
      "zalecenia": ""
    },
    "subjects": [],
    "markGroups": [],
    "grades": [],
    "teachers": {}
  }),
  'timetable-events': () => ([
    {
      "id": 173,
      "dateTimeFrom": "2026-09-28 14:25:00",
      "dateTimeTo": "2026-09-28 15:55:00",
      "subjectName": "chór",
      "bgColor": "background-color: #006600;",
      "attendanceLabel": "Obecność",
      "isLocked": 1,
      "isCyclic": 1,
      "isCanceled": 0,
      "substitution": 0,
      "room": "Aula",
      "attendanceUnchecked": 0,
      "title": "Swing Song",
      "teachers": [
        "Beata Nowak"
      ],
      "hasTest": 0,
      "tests": [],
      "relatedEventId": null,
      "relatedEventsId": []
    },
    {
      "id": 10994,
      "dateTimeFrom": "2026-09-28 11:30:00",
      "dateTimeTo": "2026-09-28 12:15:00",
      "subjectName": "język polski",
      "bgColor": "",
      "attendanceLabel": null,
      "isLocked": 0,
      "isCyclic": 1,
      "isCanceled": 1,
      "substitution": 0,
      "room": "5.12",
      "attendanceUnchecked": 1,
      "title": "",
      "teachers": [
        "Teresa Nowak"
      ],
      "hasTest": 1,
      "tests": [
        {
          "testId": 727,
          "testType": "Badanie wyników nauczania",
          "testLabel": "Dyktando"
        }
      ],
      "relatedEventId": 150190,
      "relatedEventsId": [
        150190
      ]
    },
    {
      "id": 150190,
      "dateTimeFrom": "2026-09-28 11:30:00",
      "dateTimeTo": "2026-09-28 12:15:00",
      "subjectName": "zajęcia op. wych.",
      "bgColor": "",
      "attendanceLabel": "Nieobecność",
      "isLocked": 0,
      "isCyclic": 0,
      "isCanceled": 0,
      "substitution": 1,
      "room": "5.12",
      "attendanceUnchecked": 0,
      "title": "",
      "teachers": [
        "Anna Nowak"
      ],
      "oldSubjectName": "język polski",
      "oldTeachers": [
        "Teresa Nowak"
      ],
      "hasTest": 0,
      "tests": [],
      "relatedEventId": 10994,
      "relatedEventsId": [
        10994
      ]
    }
  ]),
  'attendance-stats': () => ({
    "records": [
      {
        "d": "2026-09-02",
        "sid": 69,
        "ab": "O",
        "ca": "P",
        "tn": "Obecność"
      },
      {
        "d": "2026-09-03",
        "sid": 69,
        "ab": "NU",
        "ca": "A",
        "tn": "Nieobecność usprawiedliwiona"
      },
      {
        "d": "2026-09-04",
        "sid": 69,
        "ab": "N",
        "ca": "A",
        "tn": "Nieobecność"
      },
      {
        "d": "2026-09-05",
        "sid": 123,
        "ab": "ph",
        "ca": "A",
        "tn": "Próba chóru"
      }
    ],
    "subjects": {
      "69": "język polski",
      "123": "chór"
    },
    "terms": []
  }),
  tests: () => ({
    "count": 2,
    "items": [
      {
        "id": 709,
        "subjectName": "kształcenie słuchu",
        "dateTime": "2026-10-12 09:45:00",
        "addedTime": "2026-09-30 09:30:31",
        "title": "Interwały budowanie",
        "description": "",
        "teacherId": 5331
      },
      {
        "id": 769,
        "subjectName": "przyroda",
        "dateTime": "2026-10-08 08:00:00",
        "addedTime": "2026-09-29 12:00:00",
        "title": "dział 1",
        "description": "rozdziały 1-3",
        "teacherId": 4977
      }
    ],
    "teachers": {
      "5331": {
        "first_name": "Agnieszka",
        "surname": "Nowak",
        "id": 5331
      }
    }
  }),
  reprimands: () => ({
    "count": 1,
    "items": [
      {
        "id": 31,
        "pupilId": 6339,
        "teacherId": 5331,
        "teacherName": "Agnieszka Nowak",
        "kind": 2,
        "getDate": "2026-10-01",
        "content": "Wzorowe zachowanie na koncercie",
        "status": 1
      }
    ]
  }),
  announcements: () => ({
    "success": true,
    "data": [
      {
        "id": 12,
        "title": "Nowa aplikacja na urządzenia mobilne",
        "content": "<p>Szanowni Państwo</p>",
        "author": "mobireg",
        "login": "mobireg",
        "dateTime": "2026-09-30T15:09:03+02:00",
        "read": "2026-09-30 15:21:22",
        "type": 1,
        "kind": 1,
        "valid": "2026-10-30T23:59:59+01:00",
        "pollOpen": false,
        "answers": [],
        "userAnswer": null,
        "declined": false,
        "pending": false
      }
    ],
    "count": 1,
    "unreadCount": 0,
    "pendingCount": 0
  }),
  'notif-settings': () => ({
    marks: 1, attendance: 1, exams: 1, reprimands: 1, messages: 1,
    announcements: 1, substitutions: 1, cancellations: 1, planChanges: 1,
  }),
  'register-fcm': () => ({ success: true }),
};

const inbox = [
  { id: 20001, subject: 'Informacja o sprawdzianie z fizyki', date: '2026-03-18T14:30:00', content: 'Szanowni Państwo, informuję że w piątek 20.03 odbędzie się sprawdzian z optyki geometrycznej. Proszę o przypomnienie dzieciom o powtórzeniu materiału.', read_at: '2026-03-18T18:00:00', stared: false, author: { name: 'Piotr Zieliński' }, recipients: [{ name: 'Jan Kowalski', roleName: 'Rodzic', read_at: '2026-03-18T18:00:00' }] },
  { id: 20002, subject: 'Wycieczka do Krakowa — zgoda', date: '2026-03-15T10:00:00', content: 'Proszę o podpisanie i dostarczenie zgody na wycieczkę szkolną do Krakowa planowaną na 10-12 kwietnia. Formularz w załączniku.', read_at: null, stared: true, author: { name: 'Jan Nowak' }, recipients: [{ name: 'Jan Kowalski', roleName: 'Rodzic', read_at: null }] },
  { id: 20003, subject: 'Zebranie z rodzicami', date: '2026-03-10T08:00:00', content: 'Zapraszam na zebranie z rodzicami w dniu 25.03 o godzinie 17:00 w sali 101.', read_at: '2026-03-10T20:00:00', stared: false, author: { name: 'Anna Kowalska' }, recipients: [{ name: 'Jan Kowalski', roleName: 'Rodzic', read_at: '2026-03-10T20:00:00' }] },
];

const sent = [
  { id: 21001, subject: 'Re: Wycieczka do Krakowa — zgoda', date: '2026-03-16T09:00:00', content: 'Dziękuję za informację. Zgoda zostanie dostarczona w poniedziałek.', read_at: null, stared: false, author: { name: 'Jan Kowalski' }, recipients: [{ name: 'Jan Nowak', roleName: 'Nauczyciel', read_at: '2026-03-16T10:30:00' }] },
];

const trash = [
  { id: 22001, subject: 'Stara wiadomość', date: '2026-01-15T12:00:00', content: 'Treść starej wiadomości', read_at: '2026-01-15T14:00:00', stared: false, author: { name: 'System' }, recipients: [{ name: 'Jan Kowalski', roleName: 'Rodzic', read_at: '2026-01-15T14:00:00' }] },
];

const important = [
  { id: 20002, subject: 'Wycieczka do Krakowa — zgoda', date: '2026-03-15T10:00:00', content: 'Proszę o podpisanie i dostarczenie zgody na wycieczkę szkolną do Krakowa planowaną na 10-12 kwietnia. Formularz w załączniku.', read_at: null, stared: true, author: { name: 'Jan Nowak' }, recipients: [{ name: 'Jan Kowalski', roleName: 'Rodzic', read_at: null }] },
];

const readMessage = {
  id: 20001, subject: 'Informacja o sprawdzianie z fizyki', date: '2026-03-18T14:30:00',
  content: '<p>Szanowni Państwo,</p><p>Informuję że w piątek 20.03 odbędzie się sprawdzian z optyki geometrycznej obejmujący materiał z rozdziałów 5-7.</p><p>Proszę o przypomnienie dzieciom o powtórzeniu materiału.</p><p>Z poważaniem,<br>Piotr Zieliński</p>',
  read_at: '2026-03-18T18:00:00', stared: false, author: { name: 'Piotr Zieliński' },
  recipients: [{ name: 'Jan Kowalski', roleName: 'Rodzic', read_at: '2026-03-18T18:00:00' }], files: [],
};

const receiverTypes = {
  types: { teachers: 'Nauczyciele', educators: 'Wychowawcy', staff: 'Pracownicy' },
  users: [],
};

const receivers = [
  { id: 'user_201', name: 'Anna Kowalska', role: 'Nauczyciel' },
  { id: 'user_202', name: 'Jan Nowak', role: 'Nauczyciel' },
  { id: 'user_203', name: 'Maria Wiśniewska', role: 'Nauczyciel' },
  { id: 'user_204', name: 'Piotr Zieliński', role: 'Nauczyciel' },
  { id: 'user_205', name: 'Katarzyna Lewandowska', role: 'Nauczyciel' },
];


module.exports = {
  credentials,
  jwt,
  appViews,
  inbox,
  sent,
  trash,
  important,
  readMessage,
  receiverTypes,
  receivers,
};
