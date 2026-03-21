# mobireg-mock Testing Report

Tested: 2026-03-20
Prism version: 5.14.0
Port: 8090

## Test Summary

**12/12 integration tests pass** (test/integration/mobireg_mock_test.dart in the mobireg repo).

All mock endpoints return responses that parse correctly through the Flutter app's real parsers:
- `SyncDataParser.parse()` for mobile sync data
- `parsePocztaMessages()` for inbox/sent/trash
- Portal views (subjects, timetable-events, marks, homeworks, attendances)

## Endpoints Tested

| Endpoint | Method | Status | Notes |
|----------|--------|--------|-------|
| `/{school}/modules/api/njson.php` (Settings) | POST | OK | schoolName, version, protocol fields present |
| `/{school}/modules/api/njson.php` (ParentStudents) | POST | OK | Student list with id, name, surname, sex |
| `/{school}/modules/api/njson.php` (Full Sync) | POST | OK | All 19 data tables present, parses through SyncDataParser |
| `/{school}/modules/api/njson.php` (Invalid creds) | POST | OK | Returns `{"Err": [{"errno": 101}]}` |
| `/{school}/modules/api/njson.php` (Empty marks) | POST | OK | All arrays empty, parses without error |
| `/{school}/index.php` (Login) | POST | OK | Returns token in JSON body |
| `/api.php` (subjects) | POST | OK | List of subjects with id and name |
| `/api.php` (timetable-events) | POST | OK | Events with dateTimeFrom, subjectName, teachers array |
| `/api.php` (marks) | POST | OK | Marks with id, value, subjectId, weight |
| `/api.php` (homeworks) | POST | OK | Homeworks with subjectName, dueDate, content |
| `/api.php` (attendances) | POST | OK | Attendance stats with percent, types array |
| `/api.php` (401 Unauthorized) | POST | OK | Returns error JSON |
| `/api/messages/inbox` | POST | OK | Parses through parsePocztaMessages() |
| `/api/messages/sent` | POST | OK | Parses through parsePocztaMessages() |
| `/api/messages/read/{id}` | GET | OK | Full message with HTML content, files array |
| `/api/messages/receivers/search` | POST | OK | Returns list of receivers with id, name, role |

## Full Login Flow Test

Simulated the complete app login flow:
1. POST login -> token received
2. POST ParentStudents -> 2 students returned
3. POST full sync -> 19 data tables, all non-empty (except edge-case examples)
4. POST inbox -> 3 messages with correct fields

All steps succeeded.

## Issues Found

### Issue 1: Poczta endpoints require JSON Content-Type

**Severity**: Low (the app already sends JSON)

The Poczta endpoints (inbox, sent, trash, send) require `Content-Type: application/json`. The real mobireg Poczta API accepts both `application/x-www-form-urlencoded` and `application/json`. When form-encoded data is sent, Prism returns 415 Unsupported Media Type.

**Impact**: None for the Flutter app (it sends JSON via Dio). Could affect manual curl testing without `-H "Content-Type: application/json"`.

### Issue 2: Portal login returns JSON instead of 302 redirect

**Severity**: Medium (affects the mobireg login flow)

The real mobireg login returns a `302` redirect with the token in the `Location` header. Prism cannot return 302 redirects in static mode, so the mock returns a JSON body with the token instead.

The Flutter app's `PortalDataSource` extracts the token from the 302 redirect Location header. When using the mock, this code path fails because there's no redirect.

**Workaround**: The `MOBIREG_BASE_URL` override adjusts the base URL but not the auth flow logic. The app's `ApiClientFactory.createWebLoginClient()` sets `followRedirects: false` and checks for 302, which won't match the mock's 200 response.

**Recommendation**: Either:
1. Add a Prism proxy/callback that can return 302s, or
2. Add a `_isMockMode` flag in `MobiregDataProvider` that adjusts the login parsing when `MOBIREG_BASE_URL` is set, reading the token from JSON body instead of the Location header.

### Issue 3: Android emulator ABI mismatch (RESOLVED)

**Severity**: Resolved

The `pixel_7` emulator runs x86_64, but default Flutter debug builds only include `armeabi-v7a`. Fixed by building with all ABIs:

```bash
flutter build apk --debug --target-platform android-arm,android-arm64,android-x64 --flavor phone
```

### Issue 5: Prism cannot distinguish requests by body parameters (BLOCKER)

**Severity**: High — blocks full E2E app testing

The mobireg mobile sync API uses a single endpoint (`/{school}/modules/api/njson.php`) for all operations, distinguished by the `action` form field (e.g. `action=Settings`, `action=ParentStudents`, `action=GetData`). Prism returns the same (first) example for all requests to the same path regardless of body content.

**Impact**: When the app performs its login flow:
1. `validateCredentials()` → POST njson.php → gets Settings (correct, it's the first example)
2. `fetchStudents()` → POST njson.php → gets Settings again (wrong — needs ParentStudents)

Result: account is created with 0 students, setup flow cannot proceed.

**Verified**: App successfully authenticated, added account "osm-wroclaw", showed "Account added successfully" snackbar, but Continue button doesn't navigate because no student was returned.

**Recommendation**: Replace Prism with a lightweight custom mock server (e.g. Express.js) that routes based on request body `action` parameter. Alternatively, use a Prism callback plugin or split the mock into separate endpoints per action.

### Issue 4: Prism example selection via Prefer header is non-standard

**Severity**: Info

Prism uses the `Prefer: example=<name>` header to select named examples. Without this header, it returns the first example. The Flutter app doesn't send this header, so it always gets the default (first) example.

**Impact**: When the app hits the mock without `Prefer` headers, it will always get the "happy path" response. Error/edge-case examples (`invalidCredentials`, `emptyMarks`) are only accessible via explicit `Prefer` header.

**Recommendation**: For automated testing, use the `Prefer` header. For manual app testing, the default responses are appropriate.

## Emulator Testing Results

Tested on pixel_7 emulator (x86_64) with multi-ABI debug APK:

1. App launches successfully on x86_64 emulator
2. Provider selection shows both "Mobireg" and "Test Server" (debug build)
3. Mobireg login form: School identifier, Username, Password fields work
4. Login against mock: **Account added successfully** (snackbar shown)
5. Continue to dashboard: **BLOCKED** — no students returned due to Issue 5 (Prism returns Settings example for both validateCredentials and fetchStudents)

## Recommendations

1. **Fix Issue 5** (blocker) — replace Prism with a custom Express.js mock that routes by request body `action` parameter
2. **Fix Issue 2** — adjust portal login to handle JSON token response in mock mode
3. The integration tests in `test/integration/mobireg_mock_test.dart` pass with `Prefer` header (bypasses Issue 5) and should run in CI with Prism as a service
4. Build APKs with `--target-platform android-arm,android-arm64,android-x64` for emulator compatibility
