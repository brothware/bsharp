# Stage 2: Navigation and Dashboard Implementation Plan

**Goal:** Replace the nine-page tile carousel with a dashboard-first top level, and make the gesture grammar match the platform, clearing the last Play Store hard-fail.

**Architecture:** One vertical scroll holds the dashboard and, below it, a launcher list of section rows. Tap opens a section; right swipe always goes back, and from the top level exits the app. The rotary crown scrolls, everywhere. The dashboard is a view over providers that already exist.

**Tech Stack:** Dart 3.13.2 / Flutter 3.47.2, flutter_riverpod 3.4.2, `wear_os_scrollbar` ^1.0.0, flutter_test.

**Spec:** `/home/dawid/repos/dawid/mobireg/docs/superpowers/specs/2026-09-11-wear-redesign-design.md`, sections "The dashboard" and "Navigation".

## Global Constraints

- No em-dashes anywhere, in code, comments, commit messages or docs.
- No comments in code.
- No horizontal alignment of assignments.
- `flutter analyze lib test` must report "No issues found!" after every commit.
- `flutter test` must pass in full after every commit.
- Conventional Commits: imperative, no capital first letter, no trailing period, subject MAXIMUM 50 characters, body hard-wrapped at 72.
- Every commit ends with: `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`
- Never `git commit --no-verify`. This repo HAS a pre-commit hook at `.githooks/pre-commit` via `core.hooksPath`, running format, analyze and tests on staged files. Let it run.
- Stages 0 and 1 have landed. `WearScaffold`, `WearDisplayScope`, `WearConfirmation`, the wear type scale and the shared domain helpers all exist. Use them; do not reintroduce anything they replaced.
- The dashboard introduces NO new domain logic. It reads `currentLessonProvider`, `minuteTickProvider` and the unread-count providers from `lib/app/providers/`.

---

### Task 1: Spike `wear_os_scrollbar` on both emulators

Before any of this stage is built, prove the dependency works. It is new (1.0.0, low adoption) and the whole stage leans on it.

**Files:** `pubspec.yaml`, a throwaway screen. Nothing here is kept.

Steps:
- [ ] Add `wear_os_scrollbar: ^1.0.0` to `pubspec.yaml`, run `flutter pub get`.
- [ ] Build a throwaway screen with a `WearOsScrollbar` wrapping a 30-item `ListView`, and a second with `WearOsExpressiveItem`.
- [ ] Build and install the wear flavour on BOTH emulators:
      `flutter build apk --debug --flavor wear -t lib/main_wear.dart`
      `adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-wear-debug.apk` (5554 is round, 5556 is rectangular)
- [ ] Verify on device, with screenshots: the curved indicator appears and tracks scroll position on round; the straight variant or no indicator behaves acceptably on rectangular; item scaling works.
- [ ] Verify rotary. The plugin installs `setOnGenericMotionListener` on the decorView, which pre-empts `MainActivity.onGenericMotionEvent`. Confirm the crown scrolls the list through the plugin.
- [ ] **Decision gate.** If the indicator or rotary does not work, STOP and report. Do not proceed to Task 2 on a broken dependency; the fallback is a `WearCurvedScrollbar` `CustomPainter` of about 60 lines, reusing the arc-drawing approach already in the attendance donut.
- [ ] Revert the throwaway screen. Keep the `pubspec.yaml` change only if the spike passed.
- [ ] Commit: `build: add wear os scrollbar dependency`

---

### Task 2: Remove our rotary plumbing

Only after Task 1 proves the plugin handles rotary.

**Files:**
- Modify: `android/app/src/main/kotlin/pl/brothware/bsharp/MainActivity.kt`
- Delete: `lib/wear/wear_crown_input.dart`
- Delete: `lib/wear/widgets/wear_crown_scroll.dart`
- Modify: the screens that used `WearCrownScroll`

Android dispatches generic motion events through the view hierarchy before falling back to `Activity.onGenericMotionEvent`, so with the plugin installed our override never fires again. Leaving it is a dead code path that fails silently.

Remove the rotary `EventChannel` and the `onGenericMotionEvent` override from `MainActivity`. **Keep** the `pl.brothware.bsharp/wear` MethodChannel with `isScreenRound`: `WearScaffold` still depends on it.

Steps:
- [ ] Delete both Dart files and the Kotlin rotary code.
- [ ] Replace every `WearCrownScroll` usage with the plugin's scrollbar wrapper.
- [ ] Confirm no reference survives: `grep -rn 'WearCrownScroll\|wearCrownEvents\|bsharp/rotary' lib android`
- [ ] Analyze and test clean.
- [ ] Commit: `refactor(wear): hand rotary input to the scrollbar`

---

### Task 3: The dashboard

**Files:**
- Create: `lib/wear/screens/wear_dashboard.dart`
- Create: `lib/wear/widgets/wear_lesson_hero.dart`
- Create: `lib/wear/widgets/wear_news_badges.dart`
- Create: `test/unit/wear/wear_dashboard_test.dart`
- Modify: `lib/app/providers/dashboard_providers.dart` (add `nextSchoolDayProvider`)

The hero answers "where am I supposed to be right now"; the badges answer "is there anything new".

Hero states, driven entirely by `currentLessonProvider`'s record `({ScheduleEntry? current, ScheduleEntry? next, bool allEnded})`:

| Condition | Eyebrow | Body |
|---|---|---|
| `current != null` | `NOW` | subject, room, "ends in N min", progress |
| `current == null, next != null` | `NEXT` | subject, room, "starts in N min" |
| `allEnded` | `TOMORROW` | first lesson of the next school day with lessons |
| all null and `todayLessons` empty | `NO LESSONS` | next school day and its first lesson |
| no schedule data at all | `NO DATA` | prompt to sync |

`currentLessonProvider` already skips cancelled lessons, so do not re-filter. The countdown watches `minuteTickProvider`, which already exists and self-invalidates each minute; do not add a second timer.

`nextSchoolDayProvider` is the one genuinely new provider: the next date with at least one non-cancelled lesson. Put it in `dashboard_providers.dart` beside the others, since the phone dashboard can use it too.

Shape branching via `WearDisplayScope.of(context)`: on round the hero sits inside a circular progress arc showing how far through the lesson we are; on rectangular the same value is a linear bar beneath the countdown.

Badges: non-zero only, at most four, in priority order messages, new grades, tests within 7 days, annotations, announcements. A fifth collapses into a `+n` chip. Each badge is a 48 dp tap target that opens its section.

Steps:
- [ ] Write `wear_dashboard_test.dart` covering all five hero states by overriding the providers, asserting the eyebrow and that the room number is present; that badges appear only when non-zero and cap at four with a `+n`; and that every badge is at least 48 dp. Run at both shapes.
- [ ] Run, confirm failure.
- [ ] Implement `nextSchoolDayProvider` with its own test.
- [ ] Implement the hero, the badges and the dashboard.
- [ ] Analyze and test clean.
- [ ] Commit: `feat(wear): add a glanceable dashboard`

---

### Task 4: The launcher and the new top level

**Files:**
- Create: `lib/wear/widgets/wear_launcher_row.dart`
- Rewrite: `lib/wear/screens/wear_home.dart`
- Delete: `lib/wear/widgets/wear_forward_swipe.dart`, `lib/wear/widgets/wear_page_indicator.dart`
- Modify: every tile that used `WearForwardSwipe`
- Modify: `test/unit/wear/wear_home_test.dart`, delete `wear_forward_swipe_test.dart`

`WearHome` becomes one `CustomScrollView` inside the scrollbar wrapper: the dashboard as the first sliver, then one launcher row per section. Rows navigate to a section; they are not the sections themselves.

Each row shows its section name and a live summary: `Schedule / 6 lessons`, `Grades / 3 new`, `Attendance / 83.3%`, `Homework / 2 due`, `Tests / 1 this week`, `Annotations / -`, `Messages / 3 unread`, `Announcements / 1 new`, `Settings / Synced HH:MM`. Child mode continues to filter which rows appear.

On round, wrap rows in `WearOsExpressiveItem` so they scale toward the centre. On rectangular, render them flat.

`WearForwardSwipe` is deleted outright: its `deferToChild` hit test made the gesture fail over unpainted areas, and tap-to-open replaces it. Every tile keeps its content but loses its swipe wrapper and its own `Navigator.push`; the launcher row owns navigation now.

Steps:
- [ ] Write tests: the launcher shows one row per visible section; child mode filters rows; tapping a row pushes the right screen; each row is at least 48 dp; the dashboard is above the rows in scroll order.
- [ ] Run, confirm failure.
- [ ] Implement, deleting the two widgets and their tests.
- [ ] Confirm nothing references them: `grep -rn 'WearForwardSwipe\|WearPageIndicator' lib test`
- [ ] Analyze and test clean.
- [ ] Commit: `feat(wear): replace the carousel with a launcher`

---

### Task 5: Gesture grammar and swipe to exit

**Files:**
- Modify: `lib/wear/screens/wear_home.dart`
- Modify: `lib/wear/widgets/wear_swipe_dismiss.dart`
- Create: `test/unit/wear/wear_exit_gesture_test.dart`

The final hard-fail: a right swipe on the top-level screen currently does nothing, and exiting requires over-scrolling past the top of the carousel by 60 px, an invented gesture with no affordance.

Target grammar:

| Gesture | Meaning |
|---|---|
| swipe up/down | scroll, always |
| swipe right | back; from the top level, exits the app |
| swipe left | unassigned, reserved for the system |
| tap | open, always |
| rotary | scroll, always |

Wrap the top level so a rightward swipe calls `SystemNavigator.pop()`. Delete the over-scroll exit handler in `wear_home.dart` entirely.

Steps:
- [ ] Write a test that a rightward drag on the top level triggers the exit path, and that the old over-scroll gesture no longer exits. Use a mock or a callback seam rather than actually calling `SystemNavigator.pop` in a test.
- [ ] Run, confirm failure.
- [ ] Implement.
- [ ] Confirm the over-scroll handler is gone: `grep -n 'SystemNavigator\|_topOverscroll' lib/wear/screens/wear_home.dart`
- [ ] Analyze and test clean.
- [ ] Commit: `fix(wear): swipe right to leave the app`

---

### Task 6: Rebuild the setup flow

**Files:**
- Rewrite: `lib/wear/screens/wear_setup_screen.dart`
- Modify: `test/unit/wear/wear_setup_screen_test.dart`

Three phone-sized text fields are crammed onto a watch, and the Log in button is pushed off the bottom of the circle where it renders as a clipped green sliver. The Wear IME also takes the whole screen, and its next-field action was observed skipping a field and carrying text across.

Becomes one step per screen: school, then username, then password, then the student picker. Each step is a single large row that opens the IME on tap, with clear progress and back navigation between steps.

Also resolve the `_mapFailureMessage` duplication here: adopt the shared `failureMessage` from `lib/domain/failure_messages.dart`. Note it maps `InvalidCredentials` to `t.accounts.credentialsInvalid` where the wear copy used `t.auth.invalidCredentials`. Make that swap deliberately and say so in your report.

Steps:
- [ ] Write tests: each step shows exactly one input; advancing carries the value; back returns without losing it; the primary action is visible and at least 48 dp at both shapes; a failure renders the mapped message.
- [ ] Run, confirm failure.
- [ ] Implement.
- [ ] Analyze and test clean.
- [ ] Commit: `feat(wear): one field per screen in setup`

---

### Task 7: Device verification

Not code. Evidence.

Steps:
- [ ] Build and install on both emulators.
- [ ] Capture, on round and rectangular: the dashboard in each hero state you can reach, the launcher, a section opened by tap, swipe-right returning, and swipe-right from the top level exiting.
- [ ] Verify the rotary crown scrolls the launcher on both.
- [ ] Confirm no Flutter overflow stripe appears on any screen at either shape, and at `font_scale 1.3`.
- [ ] Save screenshots under `/tmp/claude-1000/-home-dawid-repos-dawid-mobireg/a434301f-ccd6-4772-ba3d-d0a906782739/scratchpad/after/`.
- [ ] Report what you saw, including anything that looked wrong.
