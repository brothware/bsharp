# mobireg-mock Project Rules

## Purpose
Lightweight mock server that replays mobireg-format API responses using Prism (Stoplight). Enables offline Flutter app development and automated testing without hitting real mobireg.pl servers.

## Architecture
- Single OpenAPI 3.1 spec (`openapi.yaml`) as the source of truth
- Prism serves static examples from the spec — no custom code needed
- Docker and npm for easy startup

## Conventions
- All example data uses realistic Polish school names, subjects, and teacher names
- Field names match the real mobireg API exactly (snake_case for mobile sync, camelCase for portal)
- IDs are stable across endpoints (e.g., subject ID 101 = "Matematyka" everywhere)
- Dates default to the 2025/2026 school year

## Stable Mock IDs

### Subjects
| ID  | Name              | Abbr |
|-----|-------------------|------|
| 101 | Matematyka        | Mat  |
| 102 | Język polski      | Pol  |
| 103 | Język angielski   | Ang  |
| 104 | Fizyka            | Fiz  |
| 105 | Chemia            | Che  |
| 106 | Biologia          | Bio  |
| 107 | Historia          | His  |
| 108 | Geografia         | Geo  |
| 109 | Informatyka       | Inf  |
| 110 | Wychowanie fizyczne | WF |

### Teachers
| ID  | Name                  | Login     |
|-----|-----------------------|-----------|
| 201 | Anna Kowalska         | akowalska |
| 202 | Jan Nowak             | jnowak    |
| 203 | Maria Wiśniewska      | mwisniewska |
| 204 | Piotr Zieliński       | pzielinski |
| 205 | Katarzyna Lewandowska | klewandowska |

### Students
| ID   | Name            | users_edu_id |
|------|-----------------|--------------|
| 6541 | Dawid Śliwa     | 9001         |
| 6542 | Zofia Kowalczyk | 9002         |

### Terms
| ID  | Name       | Type | Dates                     |
|-----|------------|------|---------------------------|
| 301 | 2025/2026  | Y    | 2025-09-01 — 2026-08-31   |
| 302 | Semestr I  | S    | 2025-09-01 — 2026-01-31   |
| 303 | Semestr II | S    | 2026-02-01 — 2026-06-30   |

### Groups
| ID  | Name  |
|-----|-------|
| 401 | 8a    |

### Rooms
| ID  | Name |
|-----|------|
| 501 | 101  |
| 502 | 204  |
| 503 | Sala gimnastyczna |

## Running

```bash
# npm
npm install && npm start

# Docker
docker compose up
```

Flutter app connects with:
```bash
flutter run --dart-define=MOBIREG_BASE_URL=http://localhost:8080
```

## Updating
1. Edit `openapi.yaml`
2. Run `npm run validate` to check syntax
3. Restart Prism to pick up changes
