[< Back to main README](../../../README.md) | [All providers](../../providers.md)

# Mobireg Provider

Implementation documentation for the Mobireg data provider (`MobiregDataProvider`).

> **Disclaimer**: The Mobireg integration uses an undocumented API that is not affiliated with or endorsed by Mobireg. The API may change without notice.

## APIs

`MobiregDataProvider` talks to two Mobireg services:

| API | Dart Data Source | Purpose |
|-----|-----------------|---------|
| **App API** (`auth.php` + `app.php`) | `AppApiDataSource`, `AppApiSession` | Login and every read view: account, terms, subjects, marks, timetable, attendance, tests, reprimands, announcements, push token registration |
| **Poczta** (`poczta.mobireg.pl`) | `PocztaDataSource` | Full messaging: inbox, send, search, attachments, unread count |

The app API is the one the official MobiReg 3.x app uses; the full contract
(transport, envelope, every view) is in [app-api.md](app-api.md).

School base URL pattern: `https://mobireg.pl/{school-slug}/`

## Authentication

| API | Mechanism | Implementation |
|-----|-----------|----------------|
| App API | `auth.php` takes the **plaintext** password and returns a JWT (30 days); every `app.php` call carries it | `AppApiDataSource.login`, `AppApiSession` |
| Poczta | SSO via `messagesToken` from the `users` view, then Laravel session + CSRF | `PocztaDataSource.establishSession()` |

### App API session

`AppApiSession` logs in lazily, keeps the JWT, and serialises every call
through a `SerialQueue`. HTTP 401 from `app.php` (expired or invalid token)
maps to `SessionExpired`; the session then logs in once more with the stored
password and retries the call a single time. `AppApiSessionRegistry` hands out
one session per `school/login`, so every caller on an account shares one login
and one JWT, as the official app does.

The `users` view result is cached on the session (`AppApiSession.account()`)
because it carries the pupil list, the enabled modules, `messagingUrl` and
`messagesToken`.

## Data Flow

`MobiregDataProvider.loadSchoolData()` fetches the views for one pupil:

1. **Account**: `users` gives the pupils, the enabled school modules and the
   mail SSO token
2. **Fetch**: `terms`, `subjects`, `marks` per semester, `timetable-events`
   for the whole school year in one call, `attendance-stats`, `tests`,
   `reprimands`, `announcements`; views of disabled modules are skipped
3. **Parse**: the functions in `lib/data/providers/mobireg/parsers/`
   deserialize each view into domain entities
4. **Populate**: write the entities into Riverpod state providers and store
   the raw views in the sync cache (`MobiregViewCache`) for
   `hydrateFromCache`

A failed request throws out of `loadSchoolData` instead of leaving partial
state behind, and a payload that does not match the documented shape raises a
`FormatException`.

## Debugging Cheatsheet

```bash
SCHOOL="your-school-slug"
BASE="https://mobireg.pl/${SCHOOL}/modules/api"
AGENT='MobiReg/3.1.3 (296c220)'

# Log in with the PLAINTEXT password; the JWT lives 30 days
JWT=$(curl -s "${BASE}/auth.php" -H 'Content-Type: application/json' \
  -d '{"login":"your-login","password":"your-password"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["token"])')

# The account view lists the pupils (no pupilId needed)
curl -s "${BASE}/app.php" -H "User-Agent: ${AGENT}" \
  -d "view=users&format=json&token=${JWT}&JWTToken=${JWT}" \
  | python3 -m json.tool

# Every other view needs pupilId; a wrong one answers errno 102
curl -s "${BASE}/app.php" -H "User-Agent: ${AGENT}" \
  -d "view=tests&format=json&token=${JWT}&JWTToken=${JWT}&pupilId=${PUPIL_ID}" \
  | python3 -m json.tool
```

The view list and parameters are in [app-api.md](app-api.md#views).

## Related Code

| Component | File |
|-----------|------|
| Provider interface | `lib/domain/school_data_provider.dart` |
| Mobireg provider | `lib/data/providers/mobireg/mobireg_data_provider.dart` |
| View parsers | `lib/data/providers/mobireg/parsers/` |
| View cache | `lib/data/providers/mobireg/mobireg_view_cache.dart` |
| FCM message handler | `lib/data/providers/mobireg/mobireg_message_handler.dart` |
| App API data source | `lib/data/data_sources/remote/app_api_data_source.dart` |
| App API session | `lib/data/data_sources/remote/app_api_session.dart` |
| Session registry | `lib/data/data_sources/remote/app_api_session_registry.dart` |
| Poczta data source | `lib/data/data_sources/remote/poczta_data_source.dart` |
| Error mapping interceptor | `lib/core/network/interceptors/error_mapping_interceptor.dart` |
| Error codes to AppFailure | [error-codes.md](error-codes.md) |
| App API contract | [app-api.md](app-api.md) |
| Mock server | `lib/data/providers/mobireg/test-mock/` |
