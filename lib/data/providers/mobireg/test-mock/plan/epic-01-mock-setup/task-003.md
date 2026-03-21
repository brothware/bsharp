# Task 003: Portal Endpoints and Login

## Status: Done

## Description
Define the login endpoint (POST, returns 302 with token) and the portal API endpoint (POST /api.php) with example responses for all views: users, timetable-events, attendances, marks, subjects, terms, homeworks, tests, reprimands, bulletins, changelog.

## Acceptance Criteria
- [x] POST login endpoint returns 302 with Location header containing 32-char hex token
- [x] POST /api.php defined with form-encoded request (school, token, view, params)
- [x] Example responses for each view match the portal entity parsers
- [x] `users` view returns login, name, surname, pupils[], messagesToken
- [x] `items` wrapper used where the Flutter app expects it
- [x] All field names match existing Dart parsers (camelCase for portal)
- [x] Failed login response (200 with HTML error body, no redirect)
- [x] 401 unauthorized response for expired/invalid portal token
- [x] Edge-case examples: empty marks, empty timetable-events, empty homeworks
