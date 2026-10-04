> This documents Mobireg-specific API error codes. Other data providers handle errors independently.

# Mobireg API Error Codes

Errors reach the client in three shapes. The first two come from `app.php`,
the third from `auth.php`; see [app-api.md](app-api.md#errors) for the wire
format.

| Shape | Meaning | Mapped to |
|-------|---------|-----------|
| HTTP 401 from `app.php`, body `{"status":"ERROR","message":...}` | The JWT is missing, invalid or expired | `SessionExpired`; `AppApiSession` logs in again once and retries |
| HTTP 200, envelope with `data: {"errno": N, "message": ...}` | The request was rejected by the view layer | `AppFailure.fromErrno(N, message)` |
| HTTP 200 from `auth.php` with `status != "OK"` | Wrong credentials | `InvalidCredentials` |

An envelope whose `v` differs from the supported protocol version maps to
`ProtocolMismatch`. An empty body maps to `NoData`. A non-JSON body or a
missing envelope is a `FormatException`, not a silent failure.

## errno Codes

| errno | Message | AppFailure | Description |
|-------|---------|------------|-------------|
| 101 | Login FAILED, give inputs | `AuthFailure.missingCredentials` | Missing credentials |
| 102 | Authorization error | `PupilNotOnAccount` | Wrong or missing `pupilId`, or a `GET` request. Does **not** mean an expired session any more: expiry is HTTP 401 |
| 103 | No view exist | `ServerFailure.viewNotFound` | Requested view does not exist |
| 105, 106, 107 | (varies) | `AuthFailure.invalidCredentials` | Authentication failure variants |
| 108 | Incorrect action parameter | `ServerFailure.missingParameter` | Missing required parameter for the action |
| 110 | No data send | `ServerFailure.noData` | Mutation without a data parameter |
| 111 | Update data failed | `ServerFailure.mutationFailed` | Mutation failed (wrong format or permissions) |
| 199 | (varies) | `ServerFailure.informational` | Informational |
| 200 | (varies) | `LicenseExpired` | The school's Mobireg license has expired |
| 201 | (varies) | `RateLimited` | Rate limit encountered |
| other | (varies) | `UnknownFailure(errno:)` | Unclassified |

A 102 on a view that needs a pupil usually means the `pupilId` is wrong for
this school year (ids change between years). The provider then drops the
session's cached `users` view and asks for it once more. If the pupil is
still missing, the sync fails with `PupilNotOnAccountException`: the account's
student list is replaced with the pupils `users` returned and the dashboard
asks the user to choose the student again. A pupil missing from `users` takes
the same path without waiting for a 102.

## Poczta

`poczta.mobireg.pl` is a separate Laravel application and does not use these
codes. An expired mail session surfaces as `SessionExpired` from
`PocztaDataSource`, which signs in again with the stored SSO token.
