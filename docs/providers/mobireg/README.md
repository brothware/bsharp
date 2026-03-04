[< Back to main README](../../../README.md) | [All providers](../../providers.md)

# Mobireg Provider

Implementation documentation for the Mobireg data provider (`MobiregDataProvider`).

> **Disclaimer**: The Mobireg integration uses an undocumented API that is not affiliated with or endorsed by Mobireg. The API may change without notice.

## APIs

`MobiregDataProvider` connects to five independent Mobireg APIs:

| API | Dart Data Source | Purpose |
|-----|-----------------|---------|
| **Mobile Sync** (`njson.php`) | `MobileSyncDataSource` | Full data sync — 36 tables in a single response |
| **Mobile Messages** (`messages.php`) | `MobileSyncDataSource` | Read/send messages via mobile endpoint |
| **Schedules** (`schedules.php`) | `MobileSyncDataSource` | Subject curriculum database (SQLite download) |
| **Parent Portal** (`api.php`) | `PortalDataSource` | 12 read views + 5 mutations, short-lived session token |
| **Poczta** (`poczta.mobireg.pl`) | `PocztaDataSource` | Full messaging: inbox, send, search, attachments |

School base URL pattern: `https://mobireg.pl/{school-slug}/`

## Authentication

All APIs use the same MD5-hashed password (no salt, lowercase hex). Authentication differs per API:

| API | Mechanism | Implementation |
|-----|-----------|----------------|
| Mobile Sync / Messages / Schedules | Per-request credentials (`login=eparent&pass=eparent` + user credentials) | `MobileAuthInterceptor` |
| Parent Portal | Session token (~30s TTL) obtained via web login redirect | `PortalDataSource.authenticate()` |
| Poczta | SSO via `messagesToken` from Portal `users` view, then Laravel session + CSRF | `PocztaDataSource.authenticate()` |

The `User-Agent: Andreg {device_id}` header is required for Mobile API requests — authentication fails without it.

## Data Flow

`MobiregDataProvider.loadSchoolData()` performs a full sync:

1. **Authenticate** — obtain Portal token and Poczta session
2. **Fetch** — call Mobile Sync API with a -100/+100 day window
3. **Parse** — `SyncDataParser` deserializes the 36-table JSON response into domain entities
4. **Populate** — write parsed entities into Riverpod state providers

Each sync record includes an `action` field (`I`/`U`/`D`) for incremental updates against the local Drift database.

## Debugging Cheatsheet

```bash
SCHOOL="your-school-slug"
LOGIN="your-login"
MD5_PASS=$(echo -n 'your-password' | md5sum | cut -d' ' -f1)

# Portal: get session token (expires in ~30s — chain with the next command)
TOKEN=$(curl -s -o /dev/null -w '%{redirect_url}' \
  "https://mobireg.pl/${SCHOOL}/index.php?action=login" \
  -X POST -d "queryString=&edlogin=${LOGIN}&edpass=${MD5_PASS}&resolutions=1920" \
  | grep -oP '[a-f0-9]{32}$')

# Portal: fetch a view
curl -s --compressed 'https://rodzic.mobireg.pl/api.php' \
  -X POST -d "school=${SCHOOL}&token=${TOKEN}&view=users" | python3 -m json.tool

# Mobile Sync: full sync
curl -s --compressed -H 'User-Agent: Andreg 12345' \
  "https://mobireg.pl/${SCHOOL}/modules/api/njson.php" \
  -X POST -d "login=eparent&pass=eparent&device_id=12345&app_version=42&parent_login=${LOGIN}&parent_pass=${MD5_PASS}&start_date=2025-11-20&end_date=2026-06-07&get_all_mark_groups=1&student_id=1" \
  | python3 -m json.tool
```

Portal views: `users`, `timetable-events`, `marks`, `subjects`, `terms`, `attendances`, `tests`, `homeworks`, `reprimands`, `bulletins`, `bulletin`, `changelog`

## Related Code

| Component | File |
|-----------|------|
| Provider interface | `lib/domain/school_data_provider.dart` |
| Mobireg provider | `lib/data/providers/mobireg_data_provider.dart` |
| Mobile Sync data source | `lib/data/data_sources/remote/mobile_sync_data_source.dart` |
| Portal data source | `lib/data/data_sources/remote/portal_data_source.dart` |
| Poczta data source | `lib/data/data_sources/remote/poczta_data_source.dart` |
| Sync response parser | `lib/data/services/sync_data_parser.dart` |
| Mobile auth interceptor | `lib/core/network/interceptors/mobile_auth_interceptor.dart` |
| Error mapping interceptor | `lib/core/network/interceptors/error_mapping_interceptor.dart` |
| Error codes → AppFailure | [error-codes.md](error-codes.md) |
| Sync data model (36 tables) | [data-model.md](data-model.md) |
