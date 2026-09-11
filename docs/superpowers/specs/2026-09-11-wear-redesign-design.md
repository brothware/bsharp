# Wear OS redesign

Date: 2026-09-11
Status: approved direction, pending implementation plan

## Context

A device-verified audit of `lib/wear` (38 files, 5131 lines) on a large round
(454x454 @320dpi = 227dp) and a rectangular (402x476 = 201x238dp) Wear OS 5.1
emulator found six Play Store hard-fail violations, systematic clipping on round
displays, an unreliable primary navigation gesture, and nine phone features that
never reached the watch.

The root cause of the visual damage is `WearScreenLayout`: on round displays it
applies a rectangular inset (10% sides, 4-12% top, 6% bottom) and treats it as a
safe area. All four corners of that rectangle fall outside the circle - by 49.8px
on tile screens at 454px, 42.1px at 384px. Thirteen screens inherit it.

## Goals

1. Clear all six Play Store hard-fail criteria.
2. Make shape detection drive real layout adaptation, not just padding maths -
   each shape should use its own strengths.
3. Replace the nine-page tile carousel with a dashboard-first top level.
4. Close the feature gap with the phone app.

## Non-goals

- Ambient/always-on mode. The app is not a watch face and does not need it.
- Message composing on the watch. Reading and a reply affordance are enough.
- Tiles and complications. Separate surfaces, separate project.
- Any change to phone/tablet/web *layout, navigation or behaviour*. Those
  surfaces are working and are not being redesigned.

Explicitly **in** scope, by decision: the shared semantic colour palette is
corrected for every surface, so phone, tablet and web light themes do change
appearance. See Semantic colour.

## Shape detection and adaptive layout

### `WearDisplay` model

`wearScreenShapeProvider` currently returns a two-value enum from a MethodChannel
and silently falls back to `rectangular` on `MissingPluginException`. That silent
fallback would make a round watch render the rectangular layout with no signal,
so it is replaced by a model that carries everything layout needs:

```dart
class WearDisplay {
  final WearScreenShape shape;   // round | rectangular
  final Size sizeDp;             // logical size
  bool get isSmall => sizeDp.shortestSide < 225;  // Google's breakpoint
}
```

The `MissingPluginException` path throws in debug and reports `rectangular` in
release with a logged warning - it must never fail silently (per project rules on
silent failures).

### `WearScaffold` replaces `WearScreenLayout`

One widget, used by every screen, providing a genuinely shape-correct safe area:

| Shape | Inset | Rationale |
|---|---|---|
| Round | 14.64% of diameter, uniform on all four sides | `(1 - 1/sqrt(2))/2`: the largest rectangle inscribed in the circle |
| Rectangular | 5% horizontal, 4% vertical | Wear convention; replaces today's bare `SafeArea`, which adds zero margin and lets content hit the bezel |

`WearScaffold` also:

- paints the background from the theme - black in dark, near-white in light
  (see Colour);
- exposes `WearDisplay` to descendants via an `InheritedWidget` so leaf widgets
  branch on shape without a provider read on every build;
- takes an `edgeContent` slot for widgets that *should* hug the bezel (the scroll
  indicator), which must sit outside the safe area rather than inside it.

### What each shape actually gets

This is the part that makes detection worth having. The two shapes render
different component choices, not the same layout with different padding:

| Concern | Round | Rectangular |
|---|---|---|
| Scroll indicator | Curved arc hugging the bezel (`WearOsScrollbar`) | Straight right-edge scrollbar |
| List items | Centre-weighted scaling (`WearOsExpressiveItem`), items shrink toward the curve | Flat list, no scaling, more rows visible |
| Section headers | Icon stacked above centred title | Icon and title in a left-aligned row |
| Lesson progress | Circular arc around the dashboard hero | Linear progress bar |
| Content alignment | Radiates from centre, vertically centred | Top-aligned, edge-aligned |
| Long lists | Scaling + arc indicator make position legible | Standard scrolling |

### Dependency: `wear_os_scrollbar`

Adopted at `^1.0.0` (MIT, published 2026-09; resolves cleanly against Flutter
3.47.2). It provides both pieces we need: `WearOsScrollbar` (curved indicator,
rotary handling, haptics, auto-hide) and `WearOsExpressiveItem` (scroll-position
scaling).

**Integration constraint, verified by reading the plugin source.** The plugin
installs `setOnGenericMotionListener` on `activity.window.decorView`. Android
dispatches generic motion events through the view hierarchy *before* falling back
to `Activity.onGenericMotionEvent`, so the plugin's listener consumes rotary
events first and our `MainActivity` override would never fire again. Leaving both
in place creates a dead code path that fails silently. Therefore, adopting the
package **requires** deleting:

- the rotary `EventChannel` and `onGenericMotionEvent` override in `MainActivity.kt`
- `lib/wear/wear_crown_input.dart`
- `lib/wear/widgets/wear_crown_scroll.dart`

The `pl.brothware.bsharp/wear` MethodChannel (`isScreenRound`) stays.

`WearOsScrollbar` takes `indicatorColor` and `backgroundColor` as explicit
arguments rather than reading the theme, so the `WearScrollView` wrapper passes
them from `ColorScheme` - otherwise the arc keeps its dark-theme colours on the
light surface and disappears.

Risk: the package is new (1.0.0, low adoption). Mitigation: it is confined behind
`WearScaffold` and a thin `WearScrollView` wrapper, so replacing it later touches
two files. Stage 2 begins with a spike that verifies rotary and the indicator on
both emulators before the rest of the stage is built.

## Shared code

The wear layer has been reimplementing logic the phone already has. Every item
below is real duplication found in the current tree, and closing it is a
prerequisite for the dashboard rather than a tidy-up afterwards.

### Already exists, must be reused not rewritten

`currentLessonProvider` in `dashboard_providers.dart` already returns
`({ScheduleEntry? current, ScheduleEntry? next, bool allEnded})` - exactly the
dashboard hero's state - and `minuteTickProvider` already drives a correctly
scoped per-minute rebuild via a self-invalidating timer. The dashboard is a
*view* over these, not new logic.

`wear_schedule_tile._isCurrentLesson` is a worse reimplementation of the same
thing and is deleted. It is also subtly wrong today: it does not skip cancelled
lessons, and because it reads `DateTime.now()` during build without watching
`minuteTickProvider`, the "current lesson" highlight on the watch goes stale
until some unrelated rebuild happens to refresh it.

### Duplicated helpers to extract

| Helper | Copies today | Destination |
|---|---|---|
| `formatDateShort` | `lib/domain/schedule_utils.dart` **and** a byte-identical private copy in `wear_grades_tile.dart` | delete the wear copy, use the domain one |
| flexible date parsing (`DateTime.parse` with `dd.MM.yyyy` fallback) | `wear_notes_tile`, `wear_tests_detail_screen`, `homework_screen` | `lib/domain/date_utils.dart` |
| `monthName(int)` | `wear_attendance_detail_screen`, `attendance_calendar` | `lib/domain/date_utils.dart` |
| annotation type -> icon + colour | `wear_notes_tile`, `wear_notes_detail_screen`, `notes_screen` | `lib/domain/annotation_utils.dart`, alongside the existing `gradeColor` precedent |
| `AppFailure` -> message | `wear_setup_screen`, `add_account_form` | `lib/domain/failure_messages.dart` |
| theme mode -> icon + label | `wear_settings_tile`, `settings_screen` | `lib/domain/theme_labels.dart` |
| schedule change type -> label | `wear_schedule_detail_screen` (phone renders the same states inline) | `lib/domain/schedule_utils.dart` |

`lib/domain` is the right home: it is already shared by both surfaces and
already contains Flutter-typed colour helpers (`gradeColor`, `subjectColor`), so
returning `Color`/`IconData` from it breaks no existing convention.

### Provider layering

`lib/wear` currently imports view-model providers out of
`lib/presentation/{schedule,grades,attendance,messages,more,dashboard}/providers/`.
These providers are surface-agnostic - nothing in them is phone-specific - so
they move to `lib/app/providers/`, which is already the established home for
cross-cutting providers (`auth_provider`, `sync_provider`, `locale_provider`,
`child_mode_provider`, `account_providers`). After the move neither surface
reaches into the other.

This is a mechanical move plus an import rewrite with no behaviour change, so it
lands as its own commit ahead of everything else and is validated by the existing
test suite. It is separable: if the diff proves disruptive it can be deferred
without blocking any other stage.

## The dashboard

The first screen answers two questions at a glance: *where am I supposed to be
right now*, and *is there anything new*.

It is composed entirely from existing providers - `currentLessonProvider` for the
hero, and the unread-count providers listed below for the badges. No new
domain logic is introduced.

### Layout

```
        ┌───────────────────────┐
        │        NOW            │  eyebrow: NOW / NEXT / TOMORROW
        │      English          │  subject, largest type on the screen
        │   room 3.11           │  room - the most actionable datum
        │   ends in 12 min      │  live countdown, refreshed each minute
        │                       │
        │  [✉3] [★2] [📝1]      │  news badges, non-zero only, tappable
        └───────────────────────┘
```

On round the hero is wrapped in a circular progress arc showing how far through
the lesson we are; on rectangular the same value is a linear bar under the
countdown.

### Hero state machine

Driven directly by `currentLessonProvider`'s record:

| `currentLesson` | Eyebrow | Body |
|---|---|---|
| `current != null` | `NOW` | subject, room, "ends in N min", progress |
| `current == null, next != null` | `NEXT` | subject, room, "starts in N min" |
| `allEnded == true` | `TOMORROW` | first lesson of the next school day, "08:00" |
| all null, `todayLessons` empty | `NO LESSONS` | next school day + its first lesson |
| no schedule data at all | `NO DATA` | prompt to sync |

`currentLessonProvider` already skips cancelled lessons when choosing `current`
and `next`, so no extra filtering is needed. Substitutions show the substitute
teacher. The `TOMORROW` and `NO LESSONS` cases need the next school day with
lessons, which `currentLessonProvider` does not cover; that is one small addition
to `dashboard_providers.dart` (`nextSchoolDayProvider`), useful to the phone
dashboard too.

### News badges

Shown only when non-zero, at most four, in this priority order. Each is a 48dp
tap target that opens its section directly.

| Badge | Source provider |
|---|---|
| Messages | `unreadCountProvider` |
| New grades | `newGradeIdsProvider` |
| Tests within 7 days | `upcomingTestsProvider` |
| Annotations | `unreadRemarksCount` + `unreadPraisesCount` + `unreadInfoCount` |
| Announcements | `unreadBulletinsCountProvider` |

A fifth non-zero badge collapses into a `+n` chip that opens the launcher.

### Sync status

Replaces the clipped `SnackBar`. A single line under the badges, present only
while syncing or on failure: a small spinner with "Syncing", or an error line
with a retry tap target. Success is silent - the content updating is the
feedback - but the launcher's Settings row carries a "Synced HH:MM" subtitle.

## Navigation

### Top level

`WearHome` becomes one vertical `CustomScrollView` inside a `WearOsScrollbar`:

- **Sliver 1** - the dashboard, sized to one screenful.
- **Sliver 2** - the launcher: one row per section, each with a live summary.
  Rows navigate to a section; they are not the sections themselves.

```
Schedule        6 lessons
Grades          3 new
Attendance      83.3%
Homework        2 due
Tests           1 this week
Annotations     —
Messages        3 unread
Announcements   1 new
Settings        Synced 09:41
```

Child mode continues to filter which rows appear.

Scrolling down from the dashboard continues into the launcher - one scrollable,
one crown behaviour, no page boundaries.

### Gesture grammar

| Gesture | Meaning |
|---|---|
| swipe up/down | scroll - always, everywhere |
| swipe right | back; from the top level, exits the app |
| swipe left | unassigned, reserved for the system |
| tap | open - always, everywhere |
| rotary | scroll - always, everywhere |

This clears WO-V3 (swipe to dismiss from the top level) and removes the
over-scroll-to-exit gesture, the nine-page carousel and the
pager-inside-list conflict together.

### Components removed

| Removed | Reason |
|---|---|
| `WearForwardSwipe` | Its `deferToChild` hit test made the gesture fail over unpainted areas; superseded by tap-to-open |
| `WearPageIndicator` | No pager left at the top level |
| `WearCrownScroll`, `wear_crown_input.dart` | Replaced by the plugin's rotary handling |
| `WearScreenLayout` | Replaced by `WearScaffold` |

### Components kept and fixed

- `WearSwipeDismiss` - gains `HitTestBehavior.opaque` so a drag starting over
  empty background still dismisses.
- `WearVerticalOverscrollPager` - kept for day/month paging in detail screens,
  but the gesture is no longer the only way: schedule and attendance detail gain
  an explicit `< date >` selector, reusing the pattern already in the grades
  term selector.

## Overlays

Material overlays are not watch components. Both are replaced:

- **`WearConfirmation`** - a full-screen route: icon, the question in full, and
  two stacked 48dp buttons. Replaces `AlertDialog` in logout and PIN removal,
  and fixes the overflow that currently deletes the confirmation body text.
- **Inline status** - replaces `SnackBar` everywhere (see Sync status above).

The theme picker becomes a normal pushed selection screen rather than a `Dialog`.

## Theme and typography

### Colour

The wear app keeps all three theme modes, matching the phone. What changes is
that each one is actually correct.

**Dark** - `surface` and every `surfaceContainer*` role overridden to pure
`#000000` in the wear theme only; the phone's surfaces are unchanged. Today's
`#0F1511` comes from Material 3's tinted dark surface via
`ColorScheme.fromSeed`. Pure black clears WO-V13, lets the app disappear into
the bezel on a round OLED panel, and stops lighting every pixel.

**Light** - a real light palette rather than the phone's surface reused
unchanged. On a watch the panel is small, often viewed outdoors, and ringed by a
black bezel, so the light theme needs its own treatment:

- `surface` a near-white neutral rather than a tinted container colour, so the
  disc reads as one clean surface rather than a patchwork;
- list item separation carried by spacing and weight rather than the translucent
  `withValues(alpha: ...)` fills used today, which wash out at watch size on a
  light ground;
- the corrected brand accent - `#2A7F4F` light, `#3FBE7A` dark - from the shared
  palette fix described under Semantic colour, which also stops
  `AppTheme.light()`/`AppTheme.dark()` pinning `primary: AppColors.seaGreen`
  identically into both brightnesses.

**System** - currently a lie: `wear_app.dart` hardcodes
`themeMode == ThemeMode.system ? ThemeMode.dark : themeMode`, so choosing System
silently gives dark while the picker still shows three options. The override is
removed and System follows the platform like the phone does. Note that Wear OS
reports night mode almost universally, so System will resolve to dark on most
watches in practice - the difference is that it now does so because the platform
said so, not because the app ignored the setting.

Both themes are verified on both emulators. WO-V13's black-background
requirement governs the app's default appearance, which stays black; an
explicitly user-selected light theme is a deliberate preference, the same
position the phone app takes.

The theme picker stays in wear settings, moved off `Dialog` onto a pushed
selection screen (see Overlays).

### Semantic colour

Both surfaces use one colour language, from one shared set of helpers.

**Subject colours** already come from `subjectColor(name, brightness:)` in
`lib/domain/schedule_utils.dart` - a 12-entry light palette and a 12-entry dark
palette, hashed by subject name. Wear already calls it, but only for a 3px bar on
the schedule screens, while `wear_homework_tile` uses it for text and the grades,
tests and notes screens ignore it entirely. The redesign applies it consistently,
matching the phone:

- a 4dp leading bar on lesson rows, as `lesson_card` does;
- a `withValues(alpha: 0.15)` tint behind the current lesson, as `linear_day_view`
  does - on a pure-black dark surface this reads as a subtle wash rather than the
  grey it becomes on the phone's tinted surface, which is the intended effect;
- the subject name itself tinted wherever it appears without a bar (homework,
  tests, grade rows), so a subject is recognisable by colour across every screen.

These palettes are reused unchanged. There is no wear-specific subject palette.

### The light-theme colour defect

Auditing the rest of the shared palette found the problem is not confined to
grades. **Every one of the twenty shared semantic colours fails WCAG AA against a
white surface.** They are all Material 400/500 tones - chosen to sit on a dark
ground - and the light theme uses them unchanged:

| Group | Worst case | On white |
|---|---|---|
| Brand (`AppColors`) | `accentOrange` `#FFA726` | 1.94 |
| Grades (`gradeColor`) | `gradeGood` `#FFC107` | 1.63 |
| Attendance (`AppColors`) | `attendanceLate` `#FFC107` | 1.63 |
| Attendance status (`attendanceStatusColor`) | `late` `#FFA726` | 1.94 |

Not all are text - calendar dots and lesson bars are graphical objects held to
3:1 rather than 4.5:1 - but most fail even that relaxed threshold. `gradeColor`
values *are* rendered as text in the grade chip, the subject average and the
dashboard, so 4.5:1 applies to them directly.

**Decision: fixed everywhere - phone, tablet, web and watch.** These helpers live
in `lib/domain` and `lib/core` and are shared by all surfaces, so the fix is made
once at the source. Phone and web light themes change appearance as a result;
that is intended, and is the point of the change.

Every colour-returning helper gains a `brightness` parameter mirroring
`subjectColor`'s existing signature. The dark column is today's palette
unchanged, so dark themes are byte-identical; only light gains new values:

| Token | Light (on white) | Dark (on black) |
|---|---|---|
| `primaryGreen` | `#4A7D1E` (4.95) | `#6AAF35` (7.80) |
| `seaGreen` | `#2A7F4F` (4.94) | `#3FBE7A` (8.86) |
| `primaryBlue` | `#1565C0` (5.75) | `#2196F3` (6.72) |
| `accentOrange` | `#A85F00` (4.88) | `#FFA726` (10.81) |
| `gradeExcellent` | `#2E7D32` (5.13) | `#4CAF50` (7.56) |
| `gradeVeryGood` | `#4B7C1F` (5.00) | `#8BC34A` (10.00) |
| `gradeGood` | `#8D6E00` (4.81) | `#FFC107` (12.88) |
| `gradeSatisfactory` | `#C44100` (5.12) | `#FF9800` (9.74) |
| `gradeAcceptable` | `#BF360C` (5.60) | `#FF5722` (6.64) |
| `gradeFailing` | `#C62828` (5.62) | `#F44336` (5.70) |
| `attendancePresent` | `#2E7D32` (5.13) | `#4CAF50` (7.56) |
| `attendanceAbsent` | `#C62828` (5.62) | `#F44336` (5.70) |
| `attendanceLate` | `#8D6E00` (4.81) | `#FFC107` (12.88) |
| `attendanceExcused` | `#1565C0` (5.75) | `#2196F3` (6.72) |
| status `excused` | `#1565C0` (5.75) | `#42A5F5` (7.93) |
| status `late` / `mixed` | `#A85F00` (4.88) | `#FFA726` (10.81) |
| status `noData` | `#6E6E6E` (4.86) | `#BDBDBD` (11.18) |

Contrast figures are measured against the **actual** resolved theme surfaces,
not against idealised white and black: `AppTheme.light()` resolves `surface` to
`#F6FBF3` and `AppTheme.dark()` to `#0F1511`. Against the real light surface the
current accent scores **4.05:1**, worse than the 4.25:1 it manages on pure white.

Every light value clears 4.5:1 against `#F6FBF3`; every dark value clears 4.5:1
against both `#0F1511` (phone) and `#000000` (wear). Hues are
preserved, so the app still reads as the same product - the light theme simply
uses the deeper end of each hue, which is what Material's own 700/800 tones exist
for.

Mechanically:

- `AppColors` gains light/dark pairs; the bare constants stay as the dark values
  so nothing breaks mid-refactor.
- `gradeColor`, `attendanceStatusColor` and `attendanceTypeColor` gain
  `{required Brightness brightness}`. Required rather than defaulted: every call
  site must state its surface, and the compiler finds them all rather than
  leaving a silent wrong default.
- `AppTheme.light()` and `AppTheme.dark()` stop passing `primary: seaGreen`
  identically into both brightnesses and use the matched pair.
- All call sites pass `Theme.of(context).brightness`. There are roughly a dozen,
  enumerated during planning.

A unit test asserts every token in both palettes meets its threshold - 4.5:1 for
text roles, 3:1 for graphical roles - against its own theme's surface. This is
what stops the defect returning.

## Touch targets

All interactive rows and controls move to a 48dp minimum:

| Control | Now | Target |
|---|---|---|
| PIN keypad key | 40 x 36 | 52 x 52, filling the inscribed width (3 x 52 = 156dp of 160dp available) |
| Settings row | 38 | 48 |
| Child mode item | ~28 | 48 |
| Child mode feature toggle | `SizedBox(height: 28)` | 48, fixed height removed so it grows with font scale |
| Language row | ~38 | 48 |
| Notes tab button | ~22 | 48 |

Fixed-height boxes are replaced with minimum-height constraints throughout, so
raising the system font scale grows rows instead of truncating text (WO-V1).

## Setup flow

The three-field login crams phone text fields into a watch and pushes the Log in
button off the bottom of the circle. It becomes one step per screen - school,
then username, then password, then student picker - each a single large row that
opens the IME on tap, with a progress indication and back navigation between
steps. This also fixes the observed behaviour where the Wear IME's next-field
action skips a field and carries text across.

## Feature drift

Carried over from the phone, in priority order:

1. **Student switching** - wear hard-writes `saveAccounts([account])` with a
   single `AccountStudent`. A parent with two children can only ever see one.
   Correctness, not polish.
2. **Notification tap routing** - the wear entry point has no deep-link
   handling, so a push cannot open the screen it is about.
3. **Mark-new-grades-as-read** - the tile draws the badge from
   `newGradeIdsProvider` but never clears it.
4. **Custom events / linear schedule** - no `TimelineItem` anywhere in
   `lib/wear`; the watch shows a different day than the phone.
5. **Grade detail** - category, weight and description.
6. **Due-soon highlighting** for homework and new-annotation surfacing.
7. **Messages** - inbox capped at four with no way to reach the fifth; add a
   full inbox screen and a reply affordance.
8. Confirm the watch attendance total matches the phone's after the
   stale-unexcused-absence rule.

## Delivery

Five stages, each shipping working and independently testable.

**Stage 0 - shared extraction.** Pure refactor, no behaviour change on either
surface: extract the seven duplicated helpers to `lib/domain`, delete
`wear_schedule_tile._isCurrentLesson` in favour of `currentLessonProvider`, and
move the view-model providers to `lib/app/providers/`. Validated entirely by the
existing test suite - if any phone test changes behaviour, the extraction is
wrong. Separable and deferrable.

**Stage A - shared palette.** Cross-surface and the only stage that changes
phone, tablet and web rendering, so it ships on its own with its own review and
its own before/after screenshots of the phone light theme. Adds light/dark pairs
to `AppColors`, the `brightness` parameter to `gradeColor`,
`attendanceStatusColor` and `attendanceTypeColor`, fixes `AppTheme`'s pinned
accent, updates every call site, and lands the contrast test that keeps it
fixed. Independent of all wear work - it could ship before or after Stage 1.

**Stage 1 - foundations.** `WearDisplay`, `WearScaffold`, both wear themes (black
dark surface, watch-tuned light surface, System stops being overridden),
consistent subject colouring across wear screens, type scale with floors, touch
target pass, `WearSwipeDismiss` hit-test fix, `WearConfirmation` and inline
status replacing `AlertDialog`/`SnackBar`. Clears five of six hard-fails without
touching navigation.

**Stage 2 - navigation and dashboard.** Spike `wear_os_scrollbar` on both
emulators first. Then the dashboard, the launcher column, removal of the
carousel and its gestures, top-level swipe-to-exit (the sixth hard-fail), and
the setup flow rebuild.

**Stage 3 - feature drift.** The list above, in its stated order.

## Testing

- The 30 existing wear tests must keep passing; those asserting carousel
  structure are rewritten against the launcher.
- New widget tests run each screen across the four combinations of shape (round,
  rectangular) and theme (light, dark), via a `WearDisplay` override and an
  explicit `ThemeMode`.
- A test asserting the dark wear theme's `surface` is exactly `#000000`, so the
  WO-V13 fix cannot regress.
- A shared contrast test (Stage A) covering every token in both palettes against
  its own surface - 4.5:1 for text roles, 3:1 for graphical roles. It guards
  phone, web and watch from the same class of regression.
- The existing phone/web suite must pass unchanged through Stage A; only golden
  or colour-literal assertions may need updating, and each such change is
  reviewed rather than blanket-accepted.
- A test asserting the wear type scale has no style below 10sp.
- A test asserting `WearScaffold`'s round inset keeps all four content corners
  inside the circle - the specific defect being fixed, so it cannot regress.
- Device verification of each stage on both emulators (`bsharp_wear_round`,
  `bsharp_wear_rect`), captured as screenshots.

## Risks

| Risk | Mitigation |
|---|---|
| `wear_os_scrollbar` is new and lightly adopted | Confined behind `WearScaffold` and a `WearScrollView` wrapper; stage 2 opens with a device spike before committing |
| Removing our rotary channel breaks scrolling if the plugin misbehaves | The spike verifies rotary on both emulators before `MainActivity` is touched |
| The 14.64% round inset costs usable width versus today's 10% | Offset by removing per-list 8dp padding, the centre-scaling list, and content that no longer needs to avoid clipped corners |
| Moving the view-model providers touches many phone imports | Mechanical rename with no logic change, covered by the existing suite; isolated in Stage 0 and deferrable without blocking later stages |
| The palette fix changes phone, tablet and web light themes | Deliberate and approved. Isolated in Stage A so it can be reviewed and reverted independently; dark themes are byte-identical, so only light-theme users see a change; hues are preserved, only depth changes |
| A required `brightness` parameter is a breaking change to three shared helpers | Intentional - the compiler enumerates every call site, which is safer than a default that silently picks the wrong palette on one surface |

## Open questions

1. **Does the provider move land now or later?** Stage 0's relocation to
   `lib/app/providers/` is mechanical but wide. It can ship first or be deferred
   without blocking any other stage.
