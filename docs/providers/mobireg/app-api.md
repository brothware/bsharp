# Mobireg app API (`auth.php` + `app.php`)

The API behind the official MobiReg app 3.x. Established 2026-10-04 from two
sources that agree with each other:

- **Live capture** of the official app 3.1.3 (versionCode 112, user agent
  `MobiReg/3.1.3 (296c220)`) on a rooted emulator behind mitmproxy, plus
  read-only probing with `curl`.
- **Static decompile** of its `libapp.so` (Dart 3.13.2, package `rodzic`) with
  Blutter. References like `app_api.dart` point into that decompile.

## Why this matters

Since early October 2026 every data request to the mobile-sync endpoint
`modules/api/njson.php` (full and diff sync, any date range, any
`app_version`) returns **HTTP 500 with an empty body**. Only the `Settings` and
`ParentStudents` views still answer. The official 3.x app does not contain the
string `njson.php` at all.

`app.php` is the **same view layer** as the portal's
`rodzic.mobireg.pl/api.php`: same view names, same payloads. The differences
are a JWT instead of the one-shot token + `sid`, and an envelope around the
response. The old portal still works as of 2026-10-04, but the official app no
longer uses it either.

## Transport

| Item | Value |
|---|---|
| Login | `POST https://mobireg.pl/<school>/modules/api/auth.php` |
| Data | `POST https://mobireg.pl/<school>/modules/api/app.php` |
| REST (justifications only) | `https://mobireg.pl/<school>/api/...`, `Authorization: Bearer <jwt>` |
| User agent | `MobiReg/<version> (<build>)` on app.php, REST and mail; the default `Dart/3.13 (dart:io)` on auth.php |
| Timeout | 15 s per app.php call |

The host can be overridden per account: auth.php may return an `address` field
(a bare host), which the official app stores and uses for later calls.

## Authentication and session

```
POST /<school>/modules/api/auth.php
Content-Type: application/json; charset=UTF-8
Accept: application/json

{"login": "<login>", "password": "<PLAINTEXT password>"}
```

```json
{"status": "OK", "token": "<JWT>", "user": {"id": 8256, "login": "...", "role": 2}}
```

- Success means HTTP 200 **and** `status == "OK"`; on failure the message is
  in `message`.
- The token is a JWT (HS256) with claims `uid`, `sub` (login), `rol`, `iat`,
  `exp`, `pv`. **It lives 30 days.**
- The password is plaintext, the same one the portal login uses. The MD5 hash
  that njson.php wanted is no longer needed anywhere.
- The official app logs in on every cold start, then reuses the JWT for every
  call. It keeps the JWT **and** the plaintext password in secure storage.
- **HTTP 401 from app.php means the token is invalid or expired.** The official
  app then logs the user out; it never re-logs in silently. Observed messages:
  `Brak tokenu autoryzacji (Nagłówek lub parametr 'token')` (missing) and
  `Nieprawidłowy podpis tokenu (fałszerstwo)` (bad signature).

## Data requests (`app.php`)

```
POST /<school>/modules/api/app.php
Content-Type: application/x-www-form-urlencoded

view=<name>&format=json&token=<jwt>&JWTToken=<jwt>&pupilId=<id>&<extra params>
```

- The official app sends the JWT twice (`token` and `JWTToken`). The server
  accepts any one of `token`, `JWTToken` or an `Authorization: Bearer` header,
  and does not need `format`. To blend in, send exactly what the official app
  sends.
- Every view except `users`, `notif-settings` and `register-fcm` needs
  `pupilId`.
- `GET` is not accepted: it answers errno 102.

### Envelope

```json
{"v": 1, "serverTime": "2026-10-04T21:06:32+02:00", "ttlFresh": 60, "ttlRetain": 1209600, "data": ...}
```

- `v` is the **protocol version**. The official app shows its "update
  required" screen when `v != 1`. That is the only version gate; the client's
  own version number plays no role any more.
- `ttlFresh` (seconds) is how long the client may serve a cached copy without
  asking again. `ttlRetain` (14 days) is how long a stale copy may be shown
  while offline.
- Some views wrap their payload one level deeper (`data.data`, `data.items`);
  see the table below.

### Errors

| Situation | HTTP | Body |
|---|---|---|
| No token / bad signature / expired | 401 | `{"status":"ERROR","message":...}` (no envelope) |
| Wrong or missing `pupilId`, or a `GET` request | 200 | envelope, `data: {"errno":102,"message":"Authorization error"}` |
| Unknown view | 200 | envelope, `data: {"errno":103,"message":"No view exist"}` |
| Server-side failure (for example `attendances` with these parameters) | 500 | empty |

**errno 102 no longer means "session expired"** as it did with the portal sid.
Expiry is now HTTP 401. A 102 means the request itself is wrong, usually the
`pupilId`.

## Views

Read views, all live-verified on 2026-10-04 except `announcement` (not called:
it probably marks the announcement read).

| view | extra params | `data` shape |
|---|---|---|
| `users` | none (no `pupilId`) | object: `id`, `eduId`, `firstname`, `lastname`, `role`, `email`, `pupils[{id, firstname, lastname}]`, `messagingUrl`, `messagesToken`, `homeworksUrl`, `appConfig{modules, marks, timetable, contact, ...}`, `consents` |
| `terms` | - | list: `{id, isYear, label, parentId, dateFrom, dateTo}`; the school year is the record with `isYear=1` |
| `subjects` | - | list: `{id, label}` |
| `marks` | `termId` | object: `subjects[{id, label, teachers[{id,name}], value, isFinal, suggestView, mtTeacherId}]`, `markGroups[{id, subjectId, kindLabel, markGroupId, parentMarkGroupId, bgColor, description}]`, `grades[{id, subjectId, kindLabel, value, markGroupId, date, teacherId, bgColor, description, comments}]`, `teachers{<id>: {id, first_name, surname}}`, `markDescriptives{zachowanie, obowiazkowe, zalecenia}`, optional `avg1`, `avg2` |
| `timetable-events` | `dateFrom`, `dateTo` (`YYYY-MM-DD`) | list: `{id, dateTimeFrom, dateTimeTo, subjectName, title, room, teachers[name], bgColor, attendanceLabel, attendanceUnchecked, isLocked, isCyclic, isCanceled, substitution, hasTest, tests[{testId, testType, testLabel}], relatedEventId, relatedEventsId[]}`, plus `oldSubjectName`, `oldTeachers` on substitutions |
| `attendance-stats` | - | object: `records[{d, sid, ab, ca, tn}]` (date, subject id, symbol, counts-as, type name), `subjects{<id>: name}`, `terms[...]` |
| `justification-events` | `dateFrom`, `dateTo` | `data.data{<date>: {<eventId>: {ab, st, end, sub, js, attendance_type}}}` |
| `tests` | - | object: `count`, `items[{id, subjectName, dateTime, addedTime, title, description, teacherId}]`, `teachers{...}` |
| `reprimands` | `limit` (app sends 100) | object: `count`, `items[...]` |
| `announcements` | - | `data.data[{id, title, content (HTML), author, login, dateTime, read, type, kind, valid, pollOpen, answers, userAnswer, declined, pending}]`, `count`, `unreadCount`, `pendingCount` |
| `announcements-pending` | - | `data.data[]`, `pendingCount` |
| `announcement` | `id` | announcement detail |
| `dashboard` | `weeks` (default 2), `attMode` (0 = absences only) | list: `{type: mark\|exam\|attendance\|announcement, date, data{...}}` |
| `notif-settings` | none (no `pupilId`) | `{marks, attendance, exams, reprimands, messages, announcements, substitutions, cancellations, planChanges}` |

Old portal views that also answer on app.php but that the official app does
not call: `homeworks`, `bulletins`, `bulletin`, `changelog`. The view
`attendances` returns HTTP 500 there; use `attendance-stats` and
`timetable-events` instead.

Observed `attendance-stats` codes for one pupil: `O`/`P` Obecność,
`NU`/`A` Nieobecność usprawiedliwiona, `N`/`A` Nieobecność, `ph`/`A` Próba
chóru. The `ca` (counts-as) letter is what statistics should group by. `ab` is
school-defined.

### Request sizes

`timetable-events` for a whole term (2026-09-01..2027-01-31) is a single
call: 548 events, about 13 KB gzipped, 3.4 s. A full refresh therefore needs
about six requests: `users`, `terms`, `marks` per term, one
`timetable-events` per term or year, `attendance-stats`, `tests`.

### Writes

None of these were called during the analysis.

| Operation | Request |
|---|---|
| Register FCM token | view `register-fcm`, `token=<fcm token>`, no `pupilId` |
| Notification settings | view `notif-settings`, `settings=<JSON of the nine flags>` (the official app sends this once after login) |
| Poll answer / decline | view `announcement-answer`, `id`, `answer` or `decline=1` |
| Justifications | REST, Bearer JWT: `GET /api/justifications?pupil_id=`, `GET /api/justifications/<id>`, `POST /api/justifications {pupil_id, message, event_ids}`, `PUT /api/justifications/<id> {message, event_ids}`, `DELETE /api/justifications/<id>` |

## Mail (`poczta.mobireg.pl`)

The mailbox URL and the token come from the `users` view (`messagingUrl`,
`messagesToken`), not from a separate login.

| Operation | Request |
|---|---|
| SSO | `GET <messagingUrl>/<school>/<urlencoded messagesToken>`, `Accept: text/html`; keep every `Set-Cookie` and send it as `Cookie` from then on |
| Unread count | `POST /api/unreadMessages {school, messagesToken}` (no cookie) |
| Folders | `GET /api/messages/{inbox,sent,important,trash}?limit&skip&query` (the app pages by 20) |
| Read | `GET /api/messages/read/<id>` (probably marks read) |
| Send | `POST /api/messages {title, content, odbiorcy, previousMessageId}`; attachments `POST /api/messages/<id>/files` |
| Receivers | `GET /api/messages/receivers[?type=]`, `POST /api/messages/receivers/search {query, ids}` |
| Star / restore / delete | `PUT /api/messages/<id>/stared`, `PUT /api/messages/<id>/restore`, `DELETE /api/messages/<id>` |

On 2026-10-04 the SSO, `unreadMessages` and the folder lists answered HTTP 500
for the official app too: a server-side outage, not a protocol change.

## Caching and push

The official app keeps one cache row per (account, view, pupil, params),
serves it without a request while `ttlFresh` lasts, and serves it stale while
offline until `ttlRetain`. An FCM push clears the views its `kind` affects:

| FCM `kind` | Invalidated views |
|---|---|
| `marks` | `marks`, `terms`, `dashboard` |
| `absences` | `dashboard`, `timetable-events` (that date), `attendance-stats`, `justification-events`, justifications |
| `exams` | `tests`, `dashboard` |
| `reprimands` | `reprimands`, `dashboard` |
| `announcements` | `announcements`, `announcement` |
| `substitutions`, `cancellations`, `planChanges`, `timetable` | `timetable-events` (that date), `dashboard` |
| `messages` | mail |

The kind-to-view grouping is read off the order of the decompiled code; it is
not proven by a live push.

There is no diff sync any more (njson.php's `lmt` / `last_end_date`): the
client refetches whole views and relies on `ttlFresh` plus push invalidation.

## Mapping BSharp's njson.php data onto app.php

| BSharp state (from `SyncDataParser`) | New source | Gaps |
|---|---|---|
| students | `users.pupils` | no `sex`, no `users_edu_id` (`ParentStudents` on njson.php still works for both, for now) |
| teachers | `marks.teachers`, `tests.teachers`, `marks.subjects[].teachers` | timetable events carry teacher **names** only |
| subjects | `subjects` | - |
| terms | `terms` | - |
| events, event types, rooms, event subjects | `timetable-events` (already resolved: subject name, room name, teacher names, cancel/substitution flags) | no type/room/teacher ids to join on; `MobiregScheduleResolver` becomes mostly unnecessary |
| attendances, attendance types | per lesson: `timetable-events.attendanceLabel`; statistics: `attendance-stats.records` (`ab`/`ca`/`tn`); unexcused list: `justification-events` | no per-record id; types are derived from `ab`/`ca`/`tn` |
| marks, mark groups, kinds | `marks` per `termId` (`grades`, `markGroups`, `kindLabel`, `bgColor`) | no mark scales; `weight`, `count_to_avg` are parsed by the official app but were absent in the captured data |
| term / final marks | `marks.subjects[].value`, `isFinal`, `mtTeacherId` | - |
| bulletins (portal) | `announcements` (or `bulletins`, which still exists) | `announcements` adds polls and `pending` |
| tests, homeworks, reprimands, changelog (portal) | same view names on app.php | `tests` takes no date range here |
| FCM token upload (njson.php `ParentStudents` + `token`) | view `register-fcm`, `token` | - |
| `validateCredentials` (njson.php `Settings`) | `auth.php` `status == "OK"` | - |
