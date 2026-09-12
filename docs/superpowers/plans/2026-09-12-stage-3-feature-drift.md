# Stage 3: Feature Drift Implementation Plan

**Goal:** Close the gap between the watch and the phone. The last substantive design work on `lib/wear` was 15-18 March 2026; nine phone features landed after it and none reached the watch.

**Architecture:** Almost everything here already exists in `lib/app/providers/` and `lib/domain/`. This stage is mostly wiring the watch UI to logic the phone already has, not writing new logic.

**Tech Stack:** Dart 3.13.2 / Flutter 3.47.2, flutter_riverpod 3.4.2, flutter_test.

**Spec:** `/home/dawid/repos/dawid/mobireg/docs/superpowers/specs/2026-09-11-wear-redesign-design.md`, section "Feature drift".

## Global Constraints

- No em-dashes anywhere, in code, comments, commit messages or docs.
- No comments in code.
- No horizontal alignment of assignments.
- `flutter analyze lib test` must report "No issues found!" after every commit.
- `flutter test` must pass in full after every commit.
- Conventional Commits: imperative, no capital first letter, no trailing period, subject MAXIMUM 50 characters, body hard-wrapped at 72.
- Every commit ends with: `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`
- Never `git commit --no-verify`. This repo HAS a pre-commit hook at `.githooks/pre-commit` via `core.hooksPath`. Let it run.
- Stages 0, 1 and 2 have landed. Use `WearScaffold`, `WearDisplayScope`, `showWearConfirmation`, the wear type scale, the launcher, and the shared helpers in `lib/domain`. Do not reintroduce anything they replaced.
- Never write a raw colour literal for semantic state; resolve through `SemanticPalette`.

Tasks are ordered by value. Correctness first, polish last. If time runs short, stop after Task 4 and report precisely what remains.

---

### Task 1: Student switching

**Files:**
- Modify: `lib/wear/screens/wear_setup_screen.dart`
- Create: `lib/wear/screens/wear_student_picker.dart`
- Modify: `lib/wear/screens/wear_settings_tile.dart`
- Create: `test/unit/wear/wear_student_picker_test.dart`

This is correctness, not polish. `wear_setup_screen.dart` hard-writes `saveAccounts([account])` with a single `AccountStudent`, so a parent with two children can only ever see one on the watch and has no way to switch. The phone has had multi-account and student switching since 2026-03-15.

Read `lib/presentation/common/widgets/child_switcher.dart` and `lib/app/account_providers.dart` for the established model. Persist every student the provider returns, not just the selected one, and add a picker reachable from settings that sets `activeSelectionProvider`.

Steps:
- [ ] Write tests: setup with two students persists both; the picker lists both; selecting one updates the active selection; the visible data follows the selection.
- [ ] Run, confirm failure.
- [ ] Implement.
- [ ] Analyze and test clean.
- [ ] Commit: `feat(wear): let a parent switch between students`

---

### Task 2: Notification tap routing

**Files:**
- Modify: `lib/main_wear.dart`
- Modify: `lib/wear/wear_app.dart`
- Create: `test/unit/wear/wear_notification_routing_test.dart`

The phone gained notification tap routing on 2026-03-21. The wear entry point has none, so tapping a push on the watch opens the app at the top level rather than at the thing the notification is about.

Read the phone's routing for the payload contract. The watch has no `go_router`, so route by pushing the matching screen onto the navigator instead. Handle both cold start (app launched by the tap) and warm resume.

Steps:
- [ ] Write tests covering each notification kind the server sends, asserting the right screen is pushed, plus an unknown kind falling back to the top level rather than crashing.
- [ ] Run, confirm failure.
- [ ] Implement.
- [ ] Analyze and test clean.
- [ ] Commit: `feat(wear): open the screen a push refers to`

---

### Task 3: Mark new grades as read

**Files:**
- Modify: `lib/wear/screens/wear_grades_tile.dart`, `lib/wear/screens/wear_grades_detail_screen.dart`
- Modify: `test/unit/wear/wear_grades_detail_screen_test.dart`

The wear tile reads `newGradeIdsProvider` to draw its NEW badge but never clears it, so the badge outlives the phone's and the two surfaces disagree about what the parent has seen.

Find how the phone clears it (added 2026-03-14, "persist new grade tracking with mark-as-read") and call the same path when the watch shows the grade detail.

Steps:
- [ ] Write a test: opening the grades detail clears the new-grade ids it displayed, and the badge disappears.
- [ ] Run, confirm failure.
- [ ] Implement.
- [ ] Analyze and test clean.
- [ ] Commit: `feat(wear): clear new grade badges once seen`

---

### Task 4: Grade detail content

**Files:**
- Modify: `lib/wear/screens/wear_grades_detail_screen.dart`
- Modify: its test

The wear grades screen shows bare value chips. The phone gained category, weight and description on 2026-03-21. On a watch the description is often the only thing that explains a mark, so this is the highest-value content gap.

Tapping a grade chip opens a detail view with subject, value, category, weight, date and description, inside a `WearScaffold`, scrollable, dismissible by right swipe.

Steps:
- [ ] Write tests: tapping a chip shows category, weight and description; a grade with no description renders without an empty gap; the view dismisses on right swipe.
- [ ] Run, confirm failure.
- [ ] Implement.
- [ ] Analyze and test clean.
- [ ] Commit: `feat(wear): show what a grade was actually for`

---

### Task 5: Due-soon highlighting and unread annotations

**Files:**
- Modify: `lib/wear/screens/wear_homework_tile.dart`, `lib/wear/screens/wear_notes_tile.dart`
- Modify: their tests

The tests tile already highlights upcoming items. Homework does not, though `upcomingHomeworkProvider` exists, and the annotations tile shows no unread count though `unreadRemarksCount`, `unreadPraisesCount` and `unreadInfoCount` all exist. The phone gained both on 2026-05-21.

Steps:
- [ ] Write tests: homework due within seven days is visually distinguished; the annotations tile shows the summed unread count and hides it at zero.
- [ ] Run, confirm failure.
- [ ] Implement.
- [ ] Analyze and test clean.
- [ ] Commit: `feat(wear): flag work that is due soon`

---

### Task 6: Reach every message

**Files:**
- Create: `lib/wear/screens/wear_messages_list_screen.dart`
- Modify: `lib/wear/screens/wear_messages_tile.dart`
- Create: its test

The inbox tile caps at `inbox.take(4)` with no way to reach the fifth message. The launcher row for Messages should open a full scrollable inbox.

Composing on a watch stays out of scope. A reply affordance that hands off to the phone is in scope if it is cheap; if not, say so and leave it.

Steps:
- [ ] Write tests: the list shows more than four messages; each opens its detail; unread state renders.
- [ ] Run, confirm failure.
- [ ] Implement.
- [ ] Analyze and test clean.
- [ ] Commit: `feat(wear): open the full message inbox`

---

### Task 7: Confirm the attendance totals agree

**Files:** likely none.

The phone gained "allow ignoring stale unexcused absences" on 2026-05-09. The watch reads the same `attendanceStatsProvider`, so it should already inherit it. Verify rather than assume: if the watch total differs from the phone's for the same account, find out why.

Steps:
- [ ] Write a test that the watch attendance summary equals what `attendanceStatsProvider` reports under the stale-absence setting, both on and off.
- [ ] If it already passes, say so and commit only the test.
- [ ] Commit: `test(wear): pin attendance totals to the shared rule`

---

### Task 8: Custom events on the watch

**Files:**
- Modify: `lib/wear/screens/wear_schedule_tile.dart`, `lib/wear/screens/wear_schedule_detail_screen.dart`
- Modify: their tests

The phone has custom events and a linear schedule view; `lib/wear` has no `TimelineItem` at all, so the watch shows a different day than the phone for any pupil using custom events.

Read-only on the watch: show custom events in the day alongside lessons, using `timelineItemsForDateProvider`. Creating and editing them stays on the phone.

Steps:
- [ ] Write tests: a day with a custom event shows it in time order with the lessons; a custom event is visually distinguishable from a lesson.
- [ ] Run, confirm failure.
- [ ] Implement.
- [ ] Analyze and test clean.
- [ ] Commit: `feat(wear): show custom events in the day`

---

### Task 9: Device verification

Not code. Evidence.

- [ ] Build and install on both watch emulators.
- [ ] Exercise each feature above and capture screenshots.
- [ ] Confirm no overflow stripe at either shape, in both themes, and at `font_scale 1.3`.
- [ ] Save under `/tmp/claude-1000/-home-dawid-repos-dawid-mobireg/a434301f-ccd6-4772-ba3d-d0a906782739/scratchpad/after/`.
- [ ] Report what you saw, including anything that looked wrong.
