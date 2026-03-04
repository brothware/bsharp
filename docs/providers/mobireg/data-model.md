> This documents the Mobireg sync data model. Other data providers may use different schemas.

# Mobireg Data Model

The mobile sync API returns up to 36 tables in a single JSON response.
Each record includes an `action` field: `I` (insert), `U` (update), `D` (delete).

## Entity Relationship Overview

```
Terms (school year, semesters)
  |
  +-- EventTypeTerms --> EventTypes --> Subjects
  |                        |
  |                        +-- EventTypeTeachers --> Teachers
  |                        +-- EventTypeGroups --> Groups
  |                        +-- EventTypeSchedules
  |                        |
  |                        +-- Events (individual lessons/events)
  |                             |
  |                             +-- EventSubjects (lesson topics)
  |                             +-- EventIssues
  |                             +-- EventEvents (related events)
  |                             +-- Attendances --> AttendanceTypes
  |                             +-- Marks --> MarkScales
  |                                           MarkGroups --> MarkKinds
  |                                                          MarkGroupGroups
  |                                                          MarkDivisionGroups
  |                                                          MarkScaleGroups
  |
  +-- GroupTerms --> Groups --> Students (via StudentGroups)
                       |
                       +-- GroupEducators --> Teachers
```

## Core Tables

### Settings (1 record)

Server metadata returned with every sync.

| Field | Type | Description |
|-------|------|-------------|
| version | string | Server version (e.g., "1.6.0") |
| protocol | string | Protocol version (must be "1.6.0") |
| id | string | Database snapshot ID (MD5 hash) |
| time | datetime | Server timestamp (ISO 8601) |
| permissions | integer | Permission support flag |

### Students

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| users_edu_id | integer | Education system ID |
| name | string | First name |
| surname | string | Last name |
| sex | string | Gender: "K" (female) / "M" (male) |

### Teachers

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| login | string | Login username |
| users_edu_id | integer | Education system ID |
| name | string | First name |
| surname | string | Last name |
| phone | string | Phone number |
| pin | string | PIN code |
| user_type | integer | User type flag |

### Subjects

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| subjects_edu_id | integer | Education system ID |
| name | string | Full name (e.g., "edukacja wczesnoszkolna") |
| abbr | string | Abbreviation (e.g., "EW") |

### Groups

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| parent_id | integer | Parent group ID |
| groups_edu_id | integer | Education system ID |
| name | string | Group name (e.g., "Klasa 3a, c. 8l.") |
| type | string | Group type: "C" (class), etc. |
| attr | string | Attribute |

### Terms

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| parent_id | integer | Parent term (year -> semester) |
| name | string | Name (e.g., "Rok szkolny 2025/2026") |
| type | string | "Y" (year) or semester |
| start_date | date | Start date (YYYY-MM-DD) |
| end_date | date | End date (YYYY-MM-DD) |

### Rooms

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| patrons_id | integer | FK to Teachers |
| name | string | Room number (e.g., "1.02") |
| description | string | Room description |

## Schedule Tables

### Events (Lessons)

The central schedule entity. Each record is a single lesson or event.

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| name | string | Event name (e.g., "Lekcja odwolana") |
| date | date | Date (YYYY-MM-DD) |
| number | integer | Lesson number in day |
| start_time | time | Start time (HH:MM:SS) |
| end_time | time | End time (HH:MM:SS) |
| rooms_id | integer | FK to Rooms |
| event_types_id | integer | FK to EventTypes |
| status | integer | Status (1=normal, 2=cancelled) |
| substitution | integer | Is substitution (0/1) |
| type | integer | Event type flag |
| attr | integer | Attribute flag |
| terms_id | integer | FK to Terms |
| lesson_groups_id | integer | FK to LessonGroups |
| locked | integer | Is locked (0/1) |

### EventTypes

Links subjects to their teaching context.

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| subjects_id | integer | FK to Subjects |
| teaching_level | integer | Teaching level |
| substitution | integer | Is substitution type |

### EventTypeTeachers

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| teachers_id | integer | FK to Teachers |
| event_types_id | integer | FK to EventTypes |

### EventTypeGroups

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| groups_id | integer | FK to Groups |
| event_types_id | integer | FK to EventTypes |

### EventTypeTerms

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| terms_id | integer | FK to Terms |
| event_types_id | integer | FK to EventTypes |

### EventSubjects (Lesson Topics)

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| events_id | integer | FK to Events |
| content | string | Topic/subject content |
| add_time | datetime | When the topic was added |

### EventIssues

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| events_id | integer | FK to Events |
| event_types_id | integer | FK to EventTypes |
| issues_id | integer | Issue reference |

### EventEvents

Links related events (e.g., substitution pairs).

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| events1_id | integer | FK to Events |
| events2_id | integer | FK to Events |

### Lessons (Bell Schedule)

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| lesson_groups_id | integer | FK to LessonGroups |
| lesson_number | integer | Lesson number (1, 2, 3...) |
| start_time | time | Start time (HH:MM:SS) |
| end_time | time | End time (HH:MM:SS) |

### LessonGroups

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| name | string | Group name |
| selected | integer | Is selected |

### EventTypeSchedules

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Auto-increment PK |
| event_types_id | integer | FK to EventTypes |
| schedules_id | integer | Schedule reference |
| name | string | Schedule name |
| number | string | Schedule number |

## Grade Tables

### Marks (Grades)

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| mark_groups_id | integer | FK to MarkGroups |
| mark_scales_id | integer | FK to MarkScales |
| pupil_users_id | integer | FK to Students |
| teacher_users_id | integer | FK to Teachers |
| mark_value | double | Numeric value (null if scale-based) |
| comments | string | Teacher's comments |
| weight | integer | Grade weight |
| get_date | date | Date grade was given |
| add_time | datetime | When grade was entered |
| modified | integer | Modification flag |
| events_id | integer | FK to Events (lesson) |

### MarkGroups (Grade Categories)

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| parent_id | integer | Parent MarkGroup |
| parent_type | integer | Parent type |
| mark_group_groups_id | integer | FK to MarkGroupGroups |
| is_pattern | integer | Is template |
| event_type_terms_id | integer | FK to EventTypeTerms |
| mark_kinds_id | integer | FK to MarkKinds |
| abbreviation | string | Short code |
| description | string | Description |
| mark_type | integer | Grade type |
| mark_format | string | Display format |
| mark_division_groups_id | integer | FK to MarkDivisionGroups |
| mark_scale_groups_id | integer | FK to MarkScaleGroups |
| visibility | integer | Visibility flag |
| css_style | string | CSS styling |
| position | integer | Display position |
| weight | integer | Weight |
| mark_value_range_min | double | Min value |
| mark_value_range_max | double | Max value |
| precision | double | Decimal precision |
| add_by_users_id | integer | FK to Teachers |

### MarkKinds (Grade Types)

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| parent_id | integer | Parent kind |
| name | string | Name (e.g., "Aktywnosc") |
| abbreviation | string | Short code (e.g., "A") |
| subjects_id | integer | FK to Subjects |
| public | integer | Is public |
| add_by_users_id | integer | FK to Teachers |
| default_mark_type | integer | Default grade type |
| default_mark_scale_groups_id | integer | FK to MarkScaleGroups |
| default_mark_division_groups_id | integer | FK to MarkDivisionGroups |
| default_weigth | integer | Default weight (note: misspelled in API) |
| position | integer | Display position |
| css_style | string | CSS styling |

### MarkScaleGroups

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| name | string | Scale name (e.g., "Skala W,B,D,P,S,J") |
| public | integer | Is public |
| add_by_users_id | integer | FK to Teachers |
| mark_types | string | Grade type code ("P", etc.) |
| mark_scale_group_edu_id | integer | Education system ID |
| is_system | integer | Is system-defined |
| is_default | integer | Is default scale |

### MarkScales (Grade Scale Items)

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| mark_scale_groups_id | integer | FK to MarkScaleGroups |
| abbreviation | string | Short code (e.g., "W", "5+") |
| name | string | Full name (e.g., "Wspaniala") |
| mark_value | double | Numeric value (e.g., 6.0) |
| image | string | Image path |
| classified | integer | Is classified grade |
| no_count_to_average | integer | Exclude from average |
| css_style | string | CSS styling |
| mark_scale_edu_id | integer | Education system ID |

### MarkDivisionGroups

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| mark_scale_groups_id | integer | FK to MarkScaleGroups |
| name | string | Division name |
| type | integer | Division type |
| public | integer | Is public |
| range_min | double | Minimum range |
| range_max | double | Maximum range |
| precision | double | Precision |
| add_by_users_id | integer | FK to Teachers |
| mark_division_group_edu_id | integer | Education system ID |
| range_max_to_display | double | Display max range |

### MarkGroupGroups

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| mark_division_groups_id | integer | FK to MarkDivisionGroups |
| name | string | Group name |
| parent_id | integer | Parent group |
| is_pattern | integer | Is template |
| position | integer | Display position |
| weight | integer | Weight |

### MarkGroupIssues

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| mark_groups_id | integer | FK to MarkGroups |
| issues_id | integer | Issue reference |

### Averages

Returned in sync but may be empty. Contains grade averages.

## Attendance Tables

### Attendances

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| events_id | integer | FK to Events |
| students_id | integer | FK to Students |
| types_id | integer | FK to AttendanceTypes |

Note: The JSON field is `types_id` but the DB column is `attendance_types_id`.

### AttendanceTypes

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| name | string | Full name (e.g., "Obecnosc") |
| abbr | string | Abbreviation (e.g., "O") |
| style | string | CSS style (background-color) |
| count_as | string | Counts as: "P" (present), "A" (absent) |
| type | string | Type category |

## Other Tables

### Messages

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| send_time | datetime | When sent |
| sender_users_id | integer | FK to Teachers |
| recipient_users_id | integer | Recipient user ID |
| title | string | Message subject |
| content | string | Message body |
| read_time | datetime | When read (null if unread) |
| hide | integer | Is hidden |
| files | string | Attached files |

### UserReprimands (Notes)

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| students_id | integer | FK to Students |
| teachers_id | integer | FK to Teachers |
| kinds_id | integer | Kind (0=note, 1=praise) |
| getdate | date | Date (note: no underscore in JSON) |
| content | string | Content text |
| addtime | datetime | When added (note: no underscore in JSON) |
| status | integer | Status flag |

### StudentGroups

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| students_id | integer | FK to Students |
| groups_id | integer | FK to Groups |
| number | integer | Student number in group |
| strike_off_time | datetime | When struck off |
| strike_off_reason | string | Reason for removal |

### GroupEducators

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Auto-increment PK |
| groups_id | integer | FK to Groups |
| teachers_educator_id | integer | FK to Teachers |

### GroupTerms

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Auto-increment PK |
| groups_id | integer | FK to Groups |
| terms_id | integer | FK to Terms |

### PermissionGroups

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| permission_groups_id | integer | Permission group ref |
| parent_id | integer | Parent group |
| name | string | Permission name |
| description | string | Description |
| additional_description | string | Additional info |
| image | string | Image path |

### Permissions

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| permission_groups_id | integer | FK to PermissionGroups |
| users_id | integer | User ID |
| edu_id | integer | Education system ID |
| quantitative_limit | integer | Usage limit |
| grant_time | datetime | When granted |
| expire_time | datetime | When expires |
| source | integer | Source flag |

