# Task 002: Mobile Sync Endpoints

## Status: Done

## Description
Define the `/njson.php` POST endpoint in the OpenAPI spec with example responses for Settings, ParentStudents, and full sync (Students, Teachers, Subjects, Terms, Rooms, Events, EventTypes, Marks, Attendances, etc.).

## Acceptance Criteria
- [x] POST /njson.php defined with form-encoded request body
- [x] Settings response includes schoolName, version, protocol, id, time, permissions
- [x] ParentStudents response includes student list with id, users_edu_id, name, surname, sex
- [x] Full sync response includes all data tables the parser expects
- [x] All field names match SyncDataParser expectations (snake_case)
- [x] IDs are consistent with plan/rules.md
- [x] Error response for invalid credentials (errno 101)
- [x] Edge-case examples: empty ParentStudents, empty Marks, empty Events
