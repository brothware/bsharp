# mobireg-mock

Mock server for [mobireg.pl](https://mobireg.pl) API endpoints. Express.js server that routes by request body parameters (e.g. `view=Settings` vs `view=ParentStudents`), solving the limitation where Prism couldn't distinguish requests to the same endpoint. Used for offline development and E2E testing of the the BSharp Flutter app.

The OpenAPI 3.1 spec (`openapi.yaml`) is retained as documentation and for Prism-based testing with `Prefer` headers (`npm run start:prism`).

## Prerequisites

- Node.js 22+
- npm

Or alternatively:

- Docker and Docker Compose

## Quick Start

### npm

```bash
npm install
npm start
```

The mock server starts on `http://localhost:8080`.

### Docker

```bash
docker compose up
```

## Using with BSharp Flutter App

Point the Flutter app at the mock server by passing the base URL at build time:

```bash
flutter run --dart-define=MOBIREG_BASE_URL=http://localhost:8080
```

On Android emulator, use `10.0.2.2` instead of `localhost`:

```bash
flutter run --dart-define=MOBIREG_BASE_URL=http://10.0.2.2:8080
```

## Available Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/{school}/modules/api/njson.php` | POST | Mobile sync (Settings, ParentStudents, full sync) |
| `/{school}/index.php` | POST | Portal login (returns 302 with token) |
| `/api.php` | POST | Portal API (users, timetable-events, marks, attendances, subjects, terms, homeworks, tests, reprimands, bulletins, changelog) |
| `/sso/{school}/{token}` | GET | Poczta SSO login |
| `/` | GET | Poczta homepage (HTML with CSRF token) |
| `/api/messages/inbox` | POST | Inbox messages |
| `/api/messages/sent` | POST | Sent messages |
| `/api/messages/trash` | POST | Trash messages |
| `/api/messages/important` | POST | Starred messages |
| `/api/messages/read/{id}` | GET | Read single message |
| `/api/messages/receivers` | POST | Receiver types |
| `/api/messages/receivers/search` | POST | Search receivers |
| `/api/messages` | PUT | Send message |
| `/api/messages/{id}` | DELETE | Delete message |
| `/api/messages/{id}/stared` | POST | Toggle star |
| `/api/messages/{id}/restore` | POST | Restore from trash |

Error responses (401, invalid credentials) are also defined for key endpoints.

## How to Add New Examples

1. Edit `openapi.yaml` and add a new named example under the relevant endpoint's `responses` -> `"200"` -> `content` -> `examples` section.
2. Validate the spec:
   ```bash
   npm run validate
   ```
3. Restart Prism to pick up changes. When using `docker compose`, the spec is mounted read-only so a container restart is sufficient.

To request a specific example from Prism, use the `Prefer` header:

```bash
curl -X POST http://localhost:8080/osm-wroclaw/modules/api/njson.php \
  -H "Prefer: example=emptyMarks"
```

## Dynamic Mode

Prism can generate random responses from the schema instead of returning static examples:

```bash
npm run start:dynamic
```

## Related

- [mobireg](https://github.com/dawid/mobireg) -- BSharp Flutter app (main repository)
