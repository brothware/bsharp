# Epic 01: Mock Server Setup

## Goal
Stand up a Prism-based mock server that returns realistic mobireg API responses, enabling the BSharp Flutter app to run fully offline against `http://localhost:8080`.

## Scope
- OpenAPI 3.1 spec covering all four mobireg API surfaces (mobile sync, portal, login, poczta)
- Static example responses parseable by the Flutter app's existing data layer
- Docker and npm packaging for easy startup
- Stable, cross-referenced mock data (consistent IDs across endpoints)

## Success Criteria
- `npm start` launches Prism on port 8080
- Flutter app with `--dart-define=MOBIREG_BASE_URL=http://localhost:8080` can complete full sync
- All portal views return parseable data
- Login flow returns a 302 with mock token
- Poczta endpoints return inbox/sent/trash messages

## Tasks
1. [task-001](task-001.md) — Project scaffolding (package.json, Docker, .gitignore)
2. [task-002](task-002.md) — Mobile sync endpoints (njson.php)
3. [task-003](task-003.md) — Portal endpoints (api.php) and login
4. [task-004](task-004.md) — Poczta endpoints (messages)
5. [task-005](task-005.md) — End-to-end validation with Flutter app
