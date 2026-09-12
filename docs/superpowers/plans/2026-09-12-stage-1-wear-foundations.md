# Stage 1: Wear Foundations Implementation Plan

**Goal:** Clear five of the six Play Store hard-fail criteria without touching navigation, by replacing the broken layout primitive, fixing the themes, raising the type scale and touch targets, and retiring the phone-shaped overlays.

**Architecture:** `WearScreenLayout` applies a rectangular inset on round displays, so all four corners fall outside the glass. It is replaced by `WearScaffold`, which computes a genuinely circle-safe area and branches component choices by shape. Everything else in this stage inherits that.

**Tech Stack:** Dart 3.13.2 / Flutter 3.47.2, flutter_riverpod 3.4.2, flutter_test, very_good_analysis 10.3.0.

**Spec:** `/home/dawid/repos/dawid/mobireg/docs/superpowers/specs/2026-09-11-wear-redesign-design.md`, sections "Shape detection and adaptive layout", "Theme and typography", "Touch targets", "Overlays".

**Worktree:** `/home/dawid/repos/dawid/mobireg-stage1`, branch `feat/wear-stage1-foundations`.

## Global Constraints

- No em-dashes anywhere, in code, comments, commit messages or docs.
- No comments in code.
- No horizontal alignment of assignments.
- `flutter analyze lib test` must report "No issues found!" after every commit.
- `flutter test` must pass in full after every commit.
- Conventional Commits: imperative, no capital first letter, no trailing period, subject MAXIMUM 50 characters, body hard-wrapped at 72.
- Every commit ends with: `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`
- Never `git commit --no-verify`. This repo has no git hooks.
- Stage 0 has already landed on this branch's history. The shared helpers in `lib/domain` (`parseFlexibleDate`, `monthName`, `annotationStyle`, `failureMessage`, `themeModeIcon`, `themeModeLabel`, `scheduleChangeLabel`, `formatDateShort`) and the providers at `lib/app/providers/` exist. Use them.
- **Do not touch navigation.** The vertical `PageView` carousel, `WearForwardSwipe` and the top-level exit gesture are Stage 2's. This stage must not change how screens are reached.
- The shared palette from the previous stage is available: `SemanticColor` and `SemanticPalette` in `lib/core/constants/`, with `resolve(token, brightness)`. Use it rather than any raw colour literal.
- 15 wear tests exist under `test/unit/wear/`. They must keep passing. Where a test asserts the old layout's structure, update it to assert the new one and say so in the report.

## Reference numbers (measured, use verbatim)

- Round large: 454x454 px at 320dpi = **227x227 dp**. Round small: 192 dp. Rectangular: 402x476 px = **201x238 dp**.
- Round safe area: uniform inset of **14.64%** of the diameter, all four sides. This is `(1 - 1/sqrt(2))/2`, the largest rectangle inscribed in the circle. Today's 10%/4%/6% puts all four corners outside the glass by 49.8 px at 454.
- Rectangular safe area: **5%** horizontal, **4%** vertical. Today's bare `SafeArea` adds zero margin and lets content hit the bezel.
- Wear OS minimum touch target: **48 dp**. 40 dp is tolerated only where genuinely constrained.
- Text floors: essential text **12 sp**, non-essential **10 sp**. Nothing below 10.

---

### Task 1: `WearDisplay` and `WearScaffold`

**Files:**
- Modify: `lib/wear/wear_screen_shape_provider.dart`
- Create: `lib/wear/widgets/wear_scaffold.dart`
- Delete: `lib/wear/widgets/wear_screen_layout.dart`
- Modify: `test/unit/wear/wear_screen_layout_test.dart` -> rename to `wear_scaffold_test.dart`
- Modify: the 13 screens that use `WearScreenLayout`

**Produces:**
```dart
enum WearScreenShape { round, rectangular }

class WearDisplay {
  const WearDisplay({required this.shape, required this.sizeDp});
  final WearScreenShape shape;
  final Size sizeDp;
  bool get isRound => shape == WearScreenShape.round;
  bool get isSmall => sizeDp.shortestSide < 225;
}

class WearScaffold extends ConsumerWidget {
  const WearScaffold({required this.child, this.edgeContent, super.key});
  final Widget child;
  final Widget? edgeContent;
}

class WearDisplayScope extends InheritedWidget {
  static WearDisplay of(BuildContext context);
}
```

`WearScaffold` paints the theme background, applies the shape-correct inset to `child`, and stacks `edgeContent` OUTSIDE that inset so a scroll indicator can hug the bezel. It exposes `WearDisplay` via `WearDisplayScope` so leaf widgets branch on shape without a provider read per build.

The existing `wearScreenShapeProvider` silently falls back to `rectangular` on `MissingPluginException`. Keep the fallback for release but make it loud: `assert(false, ...)` in debug and a `debugPrint` warning otherwise. It must never fail silently.

Steps:
- [ ] Write `test/unit/wear/wear_scaffold_test.dart`. The load-bearing test, which is the whole point of this stage:

```dart
testWidgets('round content box keeps all four corners inside the circle', (tester) async {
  const size = Size(227, 227);
  tester.view.physicalSize = const Size(454, 454);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(WearScreenShape.round, size));

  final box = tester.getRect(find.byKey(const Key('content')));
  final centre = Offset(size.width / 2, size.height / 2);
  final radius = size.width / 2;
  for (final corner in [box.topLeft, box.topRight, box.bottomLeft, box.bottomRight]) {
    expect(
      (corner - centre).distance,
      lessThanOrEqualTo(radius),
      reason: 'corner $corner falls outside the circle',
    );
  }
});
```
  Add a second test asserting the rectangular branch leaves a non-zero margin on all four sides, and a third asserting `edgeContent` is NOT inside the inset.
- [ ] Run, confirm the corner test fails against the old widget (it will: the old inset puts corners ~25 dp outside).
- [ ] Implement `WearDisplay`, `WearDisplayScope` and `WearScaffold`.
- [ ] Replace `WearScreenLayout` with `WearScaffold` in all 13 screens. Delete the old widget and its test file.
- [ ] `flutter analyze lib test` clean, `flutter test` passes.
- [ ] Commit: `feat(wear): add a circle-correct layout scaffold`

---

### Task 2: Wear themes

**Files:**
- Modify: `lib/wear/wear_app.dart`
- Create: `test/unit/wear/wear_theme_test.dart`

Three fixes:
1. **Dark surface to pure black.** Override `surface` and every `surfaceContainer*` role to `#000000` in the wear theme only. The phone's surfaces are not touched. This clears WO-V13 and stops lighting every pixel on OLED.
2. **Light surface tuned for a watch.** A clean near-white rather than a tinted container colour. Separation carried by spacing and weight, not by the translucent `withValues(alpha: ...)` fills that wash out at watch size on a light ground.
3. **Stop lying about System.** `wear_app.dart` currently hardcodes `themeMode == ThemeMode.system ? ThemeMode.dark : themeMode`, so choosing System silently gives dark while the picker shows three options. Delete that override and pass `themeMode` straight through.

Steps:
- [ ] Write `wear_theme_test.dart` asserting: the dark wear theme's `surface` is exactly `Color(0xFF000000)`; the light wear theme's `surface` is light (`computeLuminance() > 0.8`); and that `ThemeMode.system` is passed through rather than rewritten (assert the `MaterialApp`'s `themeMode` equals what the provider holds).
- [ ] Run, confirm failure.
- [ ] Implement.
- [ ] Analyze and test clean.
- [ ] Commit: `feat(wear): paint dark on true black and honour system`

---

### Task 3: Type scale with hard floors

**Files:**
- Modify: `lib/wear/wear_app.dart` (the `_wearTheme` text theme)
- Modify: every wear file carrying a `fontSize:` override
- Create: `test/unit/wear/wear_type_scale_test.dart`

Eleven styles sit below the 10 sp floor today. Redefine the wear text theme to this scale and delete every local `fontSize:` override:

| Role | Size | Use |
|---|---|---|
| `displaySmall` | 22 | dashboard hero subject (added now, used in Stage 2) |
| `titleMedium` | 16 | screen titles, section headers |
| `bodyLarge` | 14 | list item primary text |
| `bodyMedium` | 13 | list item secondary text |
| `labelMedium` | 12 | essential labels: badges, change chips, errors |
| `labelSmall` | 10 | non-essential only: timestamps, counts |

Specifically raise: the schedule change badge (8 -> 12), attendance calendar day numbers (8 -> 12) and weekday headers (8 -> 10), the grades NEW badge (8 -> 12), both PIN error messages (9 -> 12), all four translate button states (9 -> 10), and the child mode section label and rows (10/11 -> 12).

Steps:
- [ ] Write `wear_type_scale_test.dart` asserting no style in the wear text theme has `fontSize` below 10, iterating the `TextTheme`'s styles rather than listing them.
- [ ] Add a second test that fails if any file under `lib/wear` contains a `fontSize:` literal below 10. Implement it by reading the source files from the test. This is the guard that stops the defect returning.
- [ ] Run, confirm both fail.
- [ ] Redefine the text theme and remove every offending override.
- [ ] Analyze and test clean.
- [ ] Commit: `feat(wear): enforce legible type floors`

---

### Task 4: Touch targets

**Files:**
- Modify: `lib/wear/widgets/wear_compact_keypad.dart`
- Modify: `lib/wear/screens/wear_settings_tile.dart`
- Modify: `lib/wear/screens/wear_child_mode_screen.dart`
- Modify: `lib/wear/screens/wear_language_screen.dart`
- Modify: `lib/wear/screens/wear_notes_detail_screen.dart`
- Create: `test/unit/wear/wear_touch_target_test.dart`

| Control | Now | Target |
|---|---|---|
| PIN keypad key | 40 x 36 | 52 x 52, filling the inscribed width (3 x 52 = 156 dp of the 160 dp available on a 227 dp round watch) |
| Settings row | 38 | 48 |
| Child mode item | ~28 | 48 |
| Child mode feature toggle | fixed `SizedBox(height: 28)` | 48, fixed height removed so it grows with font scale |
| Language row | ~38 | 48 |
| Notes tab button | ~22 | 48 |

Replace every fixed-height box with a minimum-height constraint, so raising the system font scale grows the row instead of truncating text. That is what makes WO-V1 hold.

Steps:
- [ ] Write `wear_touch_target_test.dart` that pumps each of these widgets and asserts every tappable (`InkWell`, `GestureDetector`, `Switch`) has a rendered size of at least 48 dp on its smaller axis.
- [ ] Run, confirm failure.
- [ ] Implement.
- [ ] Analyze and test clean.
- [ ] Commit: `fix(wear): raise touch targets to 48dp`

---

### Task 5: Swipe-dismiss hit test

**Files:**
- Modify: `lib/wear/widgets/wear_swipe_dismiss.dart`
- Modify: `test/unit/wear/` (add a case to the relevant existing test)

`WearSwipeDismiss` wraps its child in a bare `GestureDetector`, which defaults to `HitTestBehavior.deferToChild`. A drag starting over empty background does nothing. Set `behavior: HitTestBehavior.opaque`.

Steps:
- [ ] Write a test that starts a rightward drag over a transparent region of the child and expects the route to pop. Confirm it fails today.
- [ ] Add `behavior: HitTestBehavior.opaque`.
- [ ] Analyze and test clean.
- [ ] Commit: `fix(wear): make swipe dismiss hit the whole screen`

---

### Task 6: Retire the phone-shaped overlays

**Files:**
- Create: `lib/wear/widgets/wear_confirmation.dart`
- Create: `lib/wear/widgets/wear_status_line.dart`
- Modify: `lib/wear/screens/wear_settings_tile.dart`
- Modify: `lib/wear/screens/wear_child_mode_screen.dart`
- Create: `test/unit/wear/wear_confirmation_test.dart`

`AlertDialog` overflows on a watch: on the rectangular emulator Flutter reports "BOTTOM OVERFLOWED BY 18 PIXELS", the title wraps to two lines at phone typography, and the confirmation body is squeezed out entirely, so the user is asked to confirm an action that is never stated. On round, all four dialog corners are clipped. `SnackBar` is a full-bleed rectangle whose left third falls outside the circle: "Syncing..." renders as "ncing...".

**Produces:**
```dart
Future<bool> showWearConfirmation(
  BuildContext context, {
  required IconData icon,
  required String question,
  required String confirmLabel,
  String? cancelLabel,
  bool isDestructive = false,
});
```
A full-screen pushed route inside a `WearScaffold`: icon, the question in full and never truncated, then two stacked 48 dp buttons. Returns whether the user confirmed.

`WearStatusLine` is an inline widget, not an overlay: a small spinner with a label while busy, an error row with a retry tap target on failure, and nothing on success.

Replace: the logout `AlertDialog`, the PIN removal `AlertDialog`, the theme picker `Dialog` (becomes a pushed selection screen), and the sync `SnackBar`.

Steps:
- [ ] Write `wear_confirmation_test.dart` asserting the question text is fully present (not ellipsised), both buttons are at least 48 dp, it returns true on confirm and false on cancel and on dismiss, and that nothing overflows at both shapes. Use `tester.takeException()` to assert no overflow exception was thrown.
- [ ] Run, confirm failure.
- [ ] Implement both widgets and replace all four call sites.
- [ ] Verify no `AlertDialog`, `showDialog` or `SnackBar` remains under `lib/wear`: `grep -rn 'AlertDialog\|showDialog\|SnackBar' lib/wear`. Add that as a test if practical.
- [ ] Analyze and test clean.
- [ ] Commit: `feat(wear): replace phone overlays with watch ones`

---

### Task 7: Shape-aware component choices

**Files:**
- Modify: `lib/wear/widgets/wear_tile_header.dart`
- Modify: `lib/wear/wear_screen_shape_provider.dart` (`wearListBottomInset`)
- Modify: wear list screens as needed

With `WearScaffold` handling the safe area, the ad hoc compensations can go:
- `wearListBottomInset` returns a flat 32 for round regardless of screen size. Delete it; `WearScaffold` now owns the inset.
- `WearTileHeader` already branches on shape (stacked and centred on round, left-aligned row on rectangular). Keep that, but take the shape from `WearDisplayScope.of(context)` rather than a provider read.
- Round list rows get their horizontal padding from the scaffold, so remove the per-list `EdgeInsets.fromLTRB(8, ...)` that double-insets them. This is what makes the round watch stop showing less than the rectangular one despite being wider.

Steps:
- [ ] Write a test asserting that on round, a tile's list content is wider than it was with the old double inset. Express it as: the rendered row width is at least 70% of the scaffold's content width.
- [ ] Run, confirm failure.
- [ ] Implement.
- [ ] Analyze and test clean.
- [ ] Commit: `refactor(wear): let the scaffold own list insets`

---

### Task 8: Adopt the shared helpers and delete the wear duplicates

**Files:** the wear screens carrying private duplicates.

Stage 0 extracted these to `lib/domain`. Delete each private copy and call the shared one:

| Delete | Call instead |
|---|---|
| `_parseDate` in `wear_notes_tile.dart`, `wear_tests_detail_screen.dart` | `parseFlexibleDate` |
| `_monthName` in `wear_attendance_detail_screen.dart` | `monthName` |
| `_iconForType` in `wear_notes_tile.dart`, `wear_notes_detail_screen.dart` | `annotationStyle` |
| `_mapFailureMessage` in `wear_setup_screen.dart` | `failureMessage` |
| `_themeIcon` / `_themeLabel` in `wear_settings_tile.dart` | `themeModeIcon` / `themeModeLabel` |
| `_changeLabel` in `wear_schedule_detail_screen.dart` | `scheduleChangeLabel` |
| `_formatDateShort` in `wear_grades_tile.dart` | `formatDateShort` from `schedule_utils.dart` |
| `_isCurrentLesson` in `wear_schedule_tile.dart` | `currentLessonProvider` from `lib/app/providers/dashboard_providers.dart` |

The last one is a behaviour fix, not just deduplication. `_isCurrentLesson` does not skip cancelled lessons, and because it reads `DateTime.now()` during build without watching `minuteTickProvider`, the current lesson highlight goes stale until some unrelated rebuild refreshes it. `currentLessonProvider` returns `({ScheduleEntry? current, ScheduleEntry? next, bool allEnded})` and is already correct.

Steps:
- [ ] Write a test that the schedule tile highlights the lesson `currentLessonProvider` reports as current, and highlights nothing when that is null.
- [ ] Run, confirm failure.
- [ ] Delete each private copy and wire up the shared helper.
- [ ] Verify none remain: `grep -rn '_parseDate\|_monthName\|_iconForType\|_mapFailureMessage\|_themeIcon\|_themeLabel\|_changeLabel\|_formatDateShort\|_isCurrentLesson' lib/wear`
- [ ] Analyze and test clean.
- [ ] Commit: `refactor(wear): use the shared domain helpers`

## Notes for the implementer

This stage runs on top of Stage 0, so the shared helpers and the moved providers are already in place. Import them from `package:bsharp/domain/...` and `package:bsharp/app/providers/...`.
