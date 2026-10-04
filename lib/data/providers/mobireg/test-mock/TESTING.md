# mobireg-mock Testing

## Running the integration test

```bash
cd lib/data/providers/mobireg/test-mock
npm install
PORT=8090 npm start &
cd -
flutter test --tags integration --run-skipped test/integration/mobireg_mock_test.dart
```

Stop the mock afterwards. The test connects to `localhost:8090` and fails
when nothing listens there.

## What the test covers

| Endpoint | Check |
|---|---|
| `auth.php` | `{status: OK, token}` for valid credentials, `status: ERROR` otherwise |
| `app.php` view `terms` | envelope with `v == 1` and a non-empty list |
| `app.php` view `users` | parses through `parseAccount` |
| `app.php` without a token | HTTP 401 |
| `app.php` unknown view | errno 103 in the envelope |
| SSO | `Set-Cookie` session cookie |
| inbox, sent | `POST` with the cookie, parses through `parsePocztaMessages` |
| folder list without cookie | HTTP 401 |
| read, unread count, receivers search | shapes the client reads |

## Scenarios

`POST /test/scenario` with `{"school": "osm-wroclaw", "failLogin": true}`
makes `auth.php` reject that school. `extraInbox` adds messages to the inbox.
`POST /test/reset` clears them.

## Known limits

- The mock does not send CORS headers or the proxy's `X-Cookie-Jar` response
  header, so the web build cannot complete the poczta sign-in against it.
  Test that path against the Cloudflare Worker proxy instead.
- Responses are fixtures; the mock does not model server-side state.
