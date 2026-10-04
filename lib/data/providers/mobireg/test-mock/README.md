# mobireg-mock

Mock server for the [mobireg.pl](https://mobireg.pl) app API (`auth.php`, `app.php`) and the poczta mailbox. Express.js server that routes `app.php` by its `view` form field. Used for offline development and E2E testing of the BSharp Flutter app. Log in with `user` / `pass`.

The OpenAPI 3.1 spec (`openapi.yaml`) is retained as documentation.

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

The mock server starts on `http://localhost:8080`. The integration test
(`test/integration/mobireg_mock_test.dart`) expects port 8090, so start the
mock with `PORT=8090 npm start` for it; see [TESTING.md](TESTING.md).

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
| `/{school}/modules/api/auth.php` | POST | Login (JSON `{login, password}`), returns `{status, token}` |
| `/{school}/modules/api/app.php` | POST | View envelope (`view`, `token` or `JWTToken` as form fields); 401 without a token |
| `/sso/{school}/{token}` | GET | Poczta SSO, answers with `Set-Cookie` |
| `/api/unreadMessages` | POST | Unread count as plain text |
| `/api/messages/{inbox,sent,important,trash}` | POST | Folder page `{items, total}`, needs the session cookie |
| `/api/messages/read/{id}` | GET | Read single message |
| `/api/messages/receivers` | POST | Receiver types, or receivers of a `type` |
| `/api/messages/receivers/search` | POST | Search receivers |
| `/api/messages` | PUT | Send message |
| `/api/messages/{id}` | DELETE | Delete message |
| `/api/messages/{id}/stared` | POST | Toggle star |
| `/api/messages/{id}/restore` | POST | Restore from trash |

`app.php` serves the views `users`, `terms`, `subjects`, `marks`, `timetable-events`, `attendance-stats`, `tests`, `reprimands`, `announcements`, `notif-settings` and `register-fcm`; other views answer errno 103. The school `sp5-krakow` gets a different `users` view.

## Test Controls

| Endpoint | Method | Description |
|---|---|---|
| `/test/scenario` | POST | Set per-school flags (`school`, `failLogin`, `extraInbox`) |
| `/test/reset` | POST | Clear all scenarios |
| `/test/health` | GET | Liveness and active scenarios |

## Related

- [mobireg](https://github.com/dawid/mobireg) -- BSharp Flutter app (main repository)
