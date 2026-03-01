# Mobireg API Error Codes

Both APIs return errors as JSON objects with `errno` and `message` fields:

```json
{"errno": 102, "message": "Login FAILED, incorrect device inputs"}
```

## Error Codes

| errno | Message | Category | Description |
|-------|---------|----------|-------------|
| 101 | Login FAILED, give inputs | LOGIN_ERROR | Missing login credentials |
| 102 | Login FAILED, incorrect device inputs | LOGIN_ERROR | Invalid credentials or expired session |
| 103 | No view exist | CLIENT_ERROR | Requested view does not exist |
| 105 | (varies) | LOGIN_ERROR | Authentication failure variant |
| 106 | Incorrect user inputs | LOGIN_ERROR | Authentication failure / incorrect user inputs (messages.php) |
| 107 | (varies) | LOGIN_ERROR | Authentication failure variant |
| 108 | Incorrect action parameter | CLIENT_ERROR | Missing required parameter for the action (messages.php) |
| 110 | No data send | CLIENT_ERROR | Portal mutation missing data parameter |
| 111 | Update data failed | SERVER_ERROR | Portal mutation failed (wrong format or permissions) |
| 199 | (varies) | INFO | Informational (e.g. "message id=X is already read by user id=Y") |
| 200 | (varies) | LICENSE_EXPIRED | School's Mobireg license has expired |
| 201 | (varies) | SYNC_LIMIT | Sync rate limit encountered |

## Mobile App Error Type Mapping

The mobile app maps error codes to internal error types:

| errno Range | SyncErrorType | App Behavior |
|-------------|---------------|-------------|
| 101, 102, 105, 106, 107 | `LOGIN_ERROR` | Prompts re-authentication |
| 200 | `LICENSE_EXPIRED` | Shows license expired dialog |
| 201 | `SYNC_LIMIT_ENCOUNTERED` | Backs off sync frequency |
| Other | `SERVER_RETURNED_ERROR` | Shows generic error |

## Additional App-Side Error Types

These are not server error codes but internal sync failure categories:

| SyncErrorType | Trigger |
|---------------|---------|
| `CANCELLED` | User cancelled sync |
| `DB_ERROR` | Local database error |
| `CONNECTION_PROBLEM` | Network connectivity issue |
| `SERVER_ERROR` | Non-200 HTTP status code |
| `PROTOCOL_DOESNT_MATCH` | Server protocol version != 1.6.0 |
| `DB_ID_DOESNT_MATCH` | Server database ID changed (triggers full re-sync) |
| `UNKNOWN_ERROR` | Unclassified error |

## AccountStatus Mapping (Online Provider)

When checking account validity:

| Condition | AccountStatus |
|-----------|---------------|
| errno 102, 105, 106 | `WRONG_USER_PASSWORD` |
| UnknownHostException or HTTP 404 | `WRONG_ADDRESS` |
| Other IOException | `NO_CONNECTION` |
| ServerAnswerFormatException | `WRONG_ADDRESS` |
| Other ServerAnswerErrorException | `UNKNOWN_ERROR` |
| Success | `OK` |

## Parent Portal API Specific

The parent portal (rodzic.mobireg.pl) uses the same error format but session
tokens expire quickly (~30s of inactivity). Error 102 with message
"Login failed, incorrect session id" indicates an expired token.
