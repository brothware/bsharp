# Stage 0: Shared Extraction Implementation Plan

**Goal:** Remove duplicated logic between `lib/wear` and `lib/presentation`, and move the surface-agnostic view-model providers to a neutral home, so neither surface reaches into the other.

**Architecture:** Pure refactor. Seven duplicated helpers move to `lib/domain`. Seven provider files move from `lib/presentation/*/providers/` to `lib/app/providers/`. No behaviour changes on any surface.

**Tech Stack:** Dart 3.13.2 / Flutter 3.47.2, riverpod_generator (build_runner), flutter_test, very_good_analysis 10.3.0.

**Spec:** `/home/dawid/repos/dawid/mobireg/docs/superpowers/specs/2026-09-11-wear-redesign-design.md`, section "Shared code".

**Worktree:** `/home/dawid/repos/dawid/mobireg-stage0`, branch `feat/wear-stage0-shared`.

## Global Constraints

- No em-dashes anywhere, in code, comments, commit messages or docs.
- No comments in code. Naming and structure carry the meaning.
- No horizontal alignment of assignments.
- `flutter analyze lib test` must report "No issues found!" after every commit.
- `flutter test` must pass in full after every commit. Every commit leaves the tree working.
- Conventional Commits: imperative, no capital first letter, no trailing period, subject MAXIMUM 50 characters, body hard-wrapped at 72.
- Every commit ends with: `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`
- Never `git commit --no-verify`. This repo DOES have a pre-commit hook, wired via `core.hooksPath = .githooks`, which runs `dart format`, `dart analyze --fatal-infos` and tests on staged files. Let it run.
- **This stage makes no behaviour change.** If a test's expectations need editing, that is a signal you changed behaviour. Stop and report rather than editing the test to match.
- **Do not touch `lib/wear` in Tasks 1-7.** Wear consumes these in Stage 1, which runs in parallel in another worktree. Task 8 is the only wear-facing task and it is import-only.
- Generated files (`*.g.dart`, `*.freezed.dart`) are regenerated, never hand-edited: `dart run build_runner build --delete-conflicting-outputs`.

---

### Task 1: Flexible date parsing

**Files:**
- Create: `lib/domain/date_utils.dart`
- Create: `test/unit/domain/date_utils_test.dart`
- Modify: `lib/presentation/homework/screens/homework_screen.dart` (delete its private `_parseDate`)

Three copies of the same fallback parser exist: `wear_notes_tile.dart`, `wear_tests_detail_screen.dart` and `homework_screen.dart`. Read `homework_screen.dart`'s copy first and preserve its exact semantics.

**Produces:** `DateTime parseFlexibleDate(String value)` — tries `DateTime.parse`, falls back to `dd.MM.yyyy`, returns `DateTime(2000)` when neither works.

Steps:
- [ ] Write `test/unit/domain/date_utils_test.dart` covering: ISO input, `dd.MM.yyyy` input, a malformed string returning the `DateTime(2000)` sentinel, and an empty string.
- [ ] Run it, confirm it fails to compile (file does not exist).
- [ ] Create `lib/domain/date_utils.dart` with `parseFlexibleDate`, semantics copied exactly from the existing private implementations.
- [ ] Delete the private `_parseDate` from `homework_screen.dart` and call `parseFlexibleDate`. Leave the two wear copies alone.
- [ ] Run `flutter analyze lib test` and `flutter test`. Both clean.
- [ ] Commit: `refactor(domain): extract flexible date parsing`

---

### Task 2: Month names

**Files:**
- Modify: `lib/domain/date_utils.dart`
- Modify: `test/unit/domain/date_utils_test.dart`
- Modify: `lib/presentation/attendance/widgets/attendance_calendar.dart` (delete its private `_monthName`)

**Produces:** `String monthName(int month)` returning the localised name via the existing slang keys `t.attendance.month.*`, with an empty string for out-of-range input.

Steps:
- [ ] Add tests for months 1 and 12 and an out-of-range value.
- [ ] Run, confirm failure.
- [ ] Add `monthName` to `date_utils.dart`, copying the switch from `attendance_calendar.dart` verbatim.
- [ ] Delete the private copy in `attendance_calendar.dart` and call the shared one.
- [ ] Analyze and test clean.
- [ ] Commit: `refactor(domain): extract localised month names`

---

### Task 3: Annotation icon and colour

**Files:**
- Create: `lib/domain/annotation_utils.dart`
- Create: `test/unit/domain/annotation_utils_test.dart`
- Modify: `lib/presentation/notes/screens/notes_screen.dart`

`notes_screen.dart` maps a `PortalReprimand.type` int to an icon and a colour with a private helper; `wear_notes_tile.dart` and `wear_notes_detail_screen.dart` have the same map.

**Produces:** `({IconData icon, Color color}) annotationStyle(int type, {required Brightness brightness})`

The colours today are raw `Colors.green` / `Colors.orange` / `Colors.blue`, which fail contrast on the light surface (2.65, 2.05 and 3.68 against `#F6FBF3`). Route them through the palette instead:
- type 1 (praise) -> `SemanticColor.statusPresent`
- type 2 (remark) -> `SemanticColor.statusLate`
- anything else (info) -> `SemanticColor.statusExcused`
Icons stay as they are: `Icons.emoji_events`, `Icons.warning_amber`, `Icons.info_outline`.

Steps:
- [ ] Write tests asserting each type maps to the right icon and to the right `SemanticPalette` entry, and that light and dark differ.
- [ ] Run, confirm failure.
- [ ] Create `annotation_utils.dart`.
- [ ] Update `notes_screen.dart` to use it, reading brightness from the ambient theme inside `build`.
- [ ] Analyze and test clean.
- [ ] Commit: `refactor(domain): extract annotation icon and colour`

---

### Task 4: Failure messages

**Files:**
- Create: `lib/domain/failure_messages.dart`
- Create: `test/unit/domain/failure_messages_test.dart`
- Modify: `lib/presentation/auth/widgets/add_account_form.dart`

**Produces:** `String failureMessage(AppFailure failure)` — the switch currently duplicated in `add_account_form.dart` and `wear_setup_screen.dart`.

Steps:
- [ ] Write tests covering every branch the existing switch handles plus the fallback.
- [ ] Run, confirm failure.
- [ ] Create the file, copying the switch verbatim from `add_account_form.dart`.
- [ ] Delete the private copy there and call the shared one.
- [ ] Analyze and test clean.
- [ ] Commit: `refactor(domain): extract failure message mapping`

---

### Task 5: Theme mode labels

**Files:**
- Create: `lib/domain/theme_labels.dart`
- Create: `test/unit/domain/theme_labels_test.dart`
- Modify: `lib/presentation/settings/screens/settings_screen.dart`

**Produces:** `IconData themeModeIcon(ThemeMode mode)` and `String themeModeLabel(ThemeMode mode)`.

Steps:
- [ ] Write tests for all three `ThemeMode` values against both functions.
- [ ] Run, confirm failure.
- [ ] Create the file, copying from `settings_screen.dart`.
- [ ] Delete the private copies there.
- [ ] Analyze and test clean.
- [ ] Commit: `refactor(domain): extract theme mode labels`

---

### Task 6: Schedule change labels and the duplicate date formatter

**Files:**
- Modify: `lib/domain/schedule_utils.dart`
- Modify: `test/unit/domain/schedule_utils_test.dart`

**Produces:** `String scheduleChangeLabel(ScheduleChangeType type)` in `schedule_utils.dart`, beside the existing `formatDateShort`.

Note `formatDateShort` already exists in `schedule_utils.dart`; `wear_grades_tile.dart` has a byte-identical private copy. Do not touch the wear copy here (Stage 1 deletes it). Just confirm the shared one is exported and tested.

Steps:
- [ ] Add tests for all four `ScheduleChangeType` values, and a test for `formatDateShort` if one does not already exist.
- [ ] Run, confirm failure.
- [ ] Add `scheduleChangeLabel`, copying the switch from `wear_schedule_detail_screen.dart` (read it, do not modify it).
- [ ] Analyze and test clean.
- [ ] Commit: `refactor(domain): extract schedule change labels`

---

### Task 7: Move the view-model providers

**Files:**
- Move: all seven files from `lib/presentation/{attendance,dashboard,grades,messages,more,schedule}/providers/` to `lib/app/providers/`
- Modify: every importer (~70 files in `lib` and `test`)

These providers are surface-agnostic. `lib/app/` is already the home for cross-cutting providers (`auth_provider`, `sync_provider`, `locale_provider`, `child_mode_provider`, `account_providers`).

Steps:
- [ ] `git mv` each of the seven `.dart` files into `lib/app/providers/`. Move their `.g.dart` siblings too, or delete and regenerate.
- [ ] Update the `part` directives inside each moved file if the generator requires it.
- [ ] Rewrite every import. A scripted rewrite is appropriate here; verify with `flutter analyze` rather than by eye:
      `grep -rl "presentation/[a-z]*/providers/" lib test --include=*.dart | xargs sed -i -E 's#package:bsharp/presentation/[a-z]+/providers/#package:bsharp/app/providers/#g'`
- [ ] Run `dart run build_runner build --delete-conflicting-outputs`.
- [ ] `flutter analyze lib test` clean. `flutter test` passes in full with **no test file edited**. If a test needed editing, you changed behaviour: stop and report.
- [ ] Confirm no `lib/presentation/*/providers/` directory remains: `find lib/presentation -name providers -type d`.
- [ ] Commit: `refactor(app): move view model providers to lib/app`

---

### Task 8: Point wear at the new locations

**Files:**
- Modify: imports in `lib/wear/**` only.

This is the only wear-facing task in this stage and it is import-only. Do not change any wear widget, layout, size or colour: Stage 1 owns those in a parallel worktree, and body changes here will conflict.

Steps:
- [ ] Rewrite wear imports with the same sed as Task 7, scoped to `lib/wear`.
- [ ] `flutter analyze lib test` clean, `flutter test` passes.
- [ ] Confirm the diff for this commit contains only `import` lines: `git diff --stat` and inspect.
- [ ] Commit: `refactor(wear): follow the moved provider imports`

---

## Notes for the implementer

The private helper copies inside `lib/wear` (`_parseDate`, `_monthName`, `_iconForType`, `_mapFailureMessage`, `_themeIcon`, `_themeLabel`, `_changeLabel`, `_formatDateShort`, `_isCurrentLesson`) are deliberately left in place by this stage. Stage 1 deletes them when it rewrites those screens. Creating the shared helpers is this stage's job; adopting them in wear is not.
