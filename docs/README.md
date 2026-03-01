[< Back to main README](../README.md)

> **Disclaimer**: This documentation describes a reverse-engineered, undocumented API. It is not affiliated with or endorsed by Mobireg. The API may change without notice. This information is provided for educational and interoperability purposes only.

# Mobireg e-Grade Book API

Reverse-engineered API documentation for the Mobireg e-Dziennik (electronic grade book) system,
based on the Mobireg Parent app v2.0.60.0 and the parent web portal.

## Overview

Mobireg exposes **five independent APIs** across three domains:

| API | Base URL | Auth | Format | Best For |
|-----|----------|------|--------|----------|
| **Mobile Sync API** | `{school}/modules/api/njson.php` | Per-request credentials | JSON | Full data sync (36 tables), bulk export |
| **Mobile Messages API** | `{school}/modules/api/messages.php` | Per-request credentials | JSON | Inbox, sent, read/send messages |
| **Schedules API** | `{school}/modules/api/schedules.php` | Per-request credentials | JSON / SQLite | Subject curriculum database |
| **Parent Portal API** | `https://rodzic.mobireg.pl/api.php` | Session token (~30s TTL) | JSON | 12 read views, 5 mutations |
| **Poczta (Mail) API** | `https://poczta.mobireg.pl/api/` | SSO + CSRF + Laravel session | JSON | Full messaging (inbox, send, search, attachments) |

Additional services accessible via SSO:
- **Zadania (Homework)** at `https://zadania.mobireg.pl` — homework management

The school base URL follows the pattern `https://mobireg.pl/{school-slug}/`
(e.g., `https://mobireg.pl/osm-wroclaw/`).

## Quick Start

### 1. Authenticate (Web Login)

```bash
# MD5-hash the password client-side (no salt, lowercase hex)
MD5_PASS=$(echo -n 'yourpassword' | md5sum | cut -d' ' -f1)

# Login via the web form to get a session token
TOKEN=$(curl -s -o /dev/null -w '%{redirect_url}' \
  'https://mobireg.pl/{school}/index.php?action=login' \
  -X POST -d "queryString=&edlogin={login}&edpass=${MD5_PASS}&resolutions=1920" \
  | grep -oP '[a-f0-9]{32}$')
```

The redirect URL is `https://rodzic.mobireg.pl/{school}/{token}` where `{token}`
is a 32-char hex session hash. Tokens expire after ~30 seconds of inactivity.

### 2. Parent Portal API (Simple JSON)

```bash
# Get user info, student list, and messagesToken (for SSO)
curl -s --compressed 'https://rodzic.mobireg.pl/api.php' \
  -X POST -d "school={school}&token=${TOKEN}&view=users"

# Get today's timetable
curl -s --compressed 'https://rodzic.mobireg.pl/api.php' \
  -X POST -d "school={school}&token=${TOKEN}&view=timetable-events&pupilId={id}&dateFrom=2026-02-27&dateTo=2026-02-27"

# Get grades for a term
curl -s --compressed 'https://rodzic.mobireg.pl/api.php' \
  -X POST -d "school={school}&token=${TOKEN}&view=marks&pupilId={id}&termId={termId}"
```

Available views: `users`, `timetable-events`, `marks`, `subjects`, `terms`,
`attendances`, `tests`, `homeworks`, `reprimands`, `bulletins`, `bulletin`, `changelog`

### 3. Mobile Sync API (Full Data)

The mobile API uses fixed API credentials (`login=eparent&pass=eparent`) plus
the actual user's login/password on every request:

```bash
MD5_PASS=$(echo -n 'yourpassword' | md5sum | cut -d' ' -f1)
CREDS="login=eparent&pass=eparent&device_id=12345&app_version=42&parent_login={login}&parent_pass=${MD5_PASS}"

# Get server settings (also verifies credentials)
curl -s --compressed -H 'User-Agent: Andreg 12345' \
  'https://mobireg.pl/{school}/modules/api/njson.php' \
  -X POST -d "${CREDS}&view=Settings"

# Full sync (all 36 tables, 200-day window)
curl -s --compressed -H 'User-Agent: Andreg 12345' \
  'https://mobireg.pl/{school}/modules/api/njson.php' \
  -X POST -d "${CREDS}&start_date=2025-11-20&end_date=2026-06-07&get_all_mark_groups=1&student_id={studentId}"
```

### 4. Poczta (Mail) API

Authentication uses SSO: get `messagesToken` from the `users` portal view, then:

```bash
# SSO login (sets Laravel session cookies)
curl -c cookies.txt -L "https://poczta.mobireg.pl/sso/{school}/{messagesToken}"

# Extract CSRF token from page
CSRF=$(curl -b cookies.txt -s "https://poczta.mobireg.pl" | grep -oP '"csrfToken":"[^"]+' | cut -d'"' -f4)

# Get inbox
curl -b cookies.txt -s "https://poczta.mobireg.pl/api/messages/inbox" \
  -X POST -H "Content-Type: application/json" \
  -H "X-CSRF-TOKEN: ${CSRF}" -H "X-Requested-With: XMLHttpRequest" \
  -d '{"limit":25,"skip":0}'
```

### 5. Portal Data Mutations

```bash
# Mark bulletin as read
curl -s 'https://rodzic.mobireg.pl/api.php' \
  -X POST -d "school={school}&token=${TOKEN}&data={\"bulletin\":[33]}"

# Update email
curl -s 'https://rodzic.mobireg.pl/api.php' \
  -X POST -d "school={school}&token=${TOKEN}&data={\"email\":[{\"email\":\"new@example.com\"}]}"
```

Available mutations: `bulletin` (mark read), `acceptRodo`, `email`, `password`, `allowContact`

## Authentication Details

- Password is **MD5-hashed client-side** (no salt, lowercase hex digest)
- The same MD5 hash works for both the web login and the mobile API
- Web login returns a session token valid for ~30 seconds of inactivity
- Mobile API authenticates per-request (no session/cookies needed)
- Poczta uses SSO via `messagesToken` + Laravel session with CSRF

## API Reference

See [openapi.yaml](openapi.yaml) for the complete OpenAPI 3.0 specification.

Additional docs:
- [data-model.md](data-model.md) -- Entity relationships and all synced tables
- [error-codes.md](error-codes.md) -- Error codes and their meanings

## Example Scripts

- [examples/client.py](../examples/client.py) -- Python client library (all 5 APIs)
- [examples/login.sh](../examples/login.sh) -- Shell: authenticate and get token
- [examples/fetch-schedule.sh](../examples/fetch-schedule.sh) -- Shell: get today's schedule
- [examples/fetch-grades.sh](../examples/fetch-grades.sh) -- Shell: get grades
- [examples/fetch-attendance.sh](../examples/fetch-attendance.sh) -- Shell: get attendance

## Known Endpoints

### Core APIs

| Purpose | URL |
|---------|-----|
| Mobile Sync API | `https://mobireg.pl/{school}/modules/api/njson.php` |
| Mobile Messages API | `https://mobireg.pl/{school}/modules/api/messages.php` |
| Schedules / Subject DB | `https://mobireg.pl/{school}/modules/api/schedules.php` |
| Parent Portal API | `https://rodzic.mobireg.pl/api.php` |
| Poczta (Mail) API | `https://poczta.mobireg.pl/api/messages/*` |
| Zadania (Homework) | `https://zadania.mobireg.pl/api/*` |

### Infrastructure

| Purpose | URL |
|---------|-----|
| School e-Dziennik | `https://mobireg.pl/{school}/` |
| Device Registration | `https://mobireg.pl/devices/eparent/devices/addconfig.py` |
| App Updates | `https://mobireg.pl/devices/eparent/updates/update.php` |
| Feedback | `https://mobireg.pl/devices/eparent/feedback/addfeedback.py` |
| Log Upload | `https://mobireg.pl/devices/eparent/logs/logupload.py` |
| Banner Config | `https://mobireg.pl/devices/banner/get_banner_config.py` |

## Protocol Details

- **Protocol version**: 1.6.0
- **Mobile API encoding**: UTF-8
- **Web portal encoding**: ISO-8859-2
- **Mobile API compression**: gzip (send `Accept-Encoding: gzip,deflate`)
- **Mobile User-Agent**: `Andreg {device_id}` (required, auth fails without it)
- **Sync window**: App syncs -100 to +100 days from current date
- **Record actions**: `I` (insert), `U` (update), `D` (delete)
- **Full sync returns**: 36 tables regardless of `view` parameter (when `start_date`/`end_date` present)
