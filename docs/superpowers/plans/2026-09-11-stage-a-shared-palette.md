# Stage A: Shared Semantic Palette Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every shared semantic colour brightness-aware so the light theme stops using colours picked for a dark surface, on phone, tablet, web and watch alike.

**Architecture:** A single `SemanticPalette` keyed by a `SemanticColor` enum holds a light map and a dark map. The existing colour helpers (`gradeColor`, `attendanceStatusColor`, `attendanceTypeColor`) gain a required `brightness` parameter and resolve through it. `AppTheme` stops pinning the raw brand green into both brightnesses. A contrast test iterates the enum and fails the build if any token drops below 4.5:1 against its own theme's real surface.

**Tech Stack:** Dart 3.13.2 / Flutter 3.47.2, `flutter_test`, `very_good_analysis` 10.3.0.

**Spec:** `docs/superpowers/specs/2026-09-11-wear-redesign-design.md` (section "The light-theme colour defect")

## Global Constraints

- No em-dashes in any code, comment, commit message or doc.
- No comments in code. Names and structure carry the meaning.
- No horizontal alignment of assignments.
- Lint: `very_good_analysis` 10.3.0 must pass with zero new warnings.
- Never skip git hooks. No `--no-verify`.
- Commit messages: Conventional Commits, imperative, no capital, no period, body wrapped at 72 characters, subject 50 max.
- Every commit ends with: `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`
- Every commit must leave the full suite green: `flutter test`.
- Dark-theme values are today's constants verbatim. Any diff that changes a dark-theme colour is a bug in this stage.
- Measured against the real resolved surfaces: `AppTheme.light().colorScheme.surface` is `#F6FBF3`, `AppTheme.dark().colorScheme.surface` is `#0F1511`. Wear additionally uses `#000000`.
- Target: every token >= 4.5:1 against its own theme's surface.

## File Structure

| File | Responsibility |
|---|---|
| `lib/core/constants/semantic_color.dart` (create) | The `SemanticColor` enum: the canonical token list |
| `lib/core/constants/semantic_palette.dart` (create) | Light and dark maps plus `resolve(token, brightness)` |
| `lib/core/constants/app_colors.dart` (modify) | Keeps only the gradient constants; grade, attendance and brand colours move to the palette |
| `lib/domain/grade_utils.dart` (modify) | `gradeColor` gains `{required Brightness brightness}` |
| `lib/domain/attendance_utils.dart` (modify) | `attendanceStatusColor`, `attendanceTypeColor` gain the same |
| `lib/presentation/common/theme/app_theme.dart` (modify) | Stops pinning `primary` identically across brightnesses |
| 19 call sites in `lib/presentation` and `lib/wear` (modify) | Pass `Theme.of(context).brightness` |
| `test/unit/core/semantic_palette_test.dart` (create) | Contrast test over every token, both brightnesses |
| `test/unit/domain/grade_utils_test.dart` (modify) | Existing assertions gain a brightness argument |

---

### Task 1: The token enum and palette

**Files:**
- Create: `lib/core/constants/semantic_color.dart`
- Create: `lib/core/constants/semantic_palette.dart`
- Test: `test/unit/core/semantic_palette_test.dart`

**Interfaces:**
- Consumes: nothing
- Produces:
  - `enum SemanticColor { brandPrimary, brandSecondary, brandTertiary, gradeExcellent, gradeVeryGood, gradeGood, gradeSatisfactory, gradeAcceptable, gradeFailing, attendancePresent, attendanceAbsent, attendanceLate, attendanceExcused, statusPresent, statusExcused, statusUnexcused, statusLate, statusMixed, statusNoData }`
  - `abstract final class SemanticPalette { static Color resolve(SemanticColor token, Brightness brightness); static Map<SemanticColor, Color> light; static Map<SemanticColor, Color> dark; }`

- [ ] **Step 1: Write the failing test**

Create `test/unit/core/semantic_palette_test.dart`:

```dart
import 'package:bsharp/core/constants/semantic_color.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SemanticColor covers every shared token', () {
    expect(SemanticColor.values.length, 19);
  });
}
```

The contrast assertions arrive in Task 2, once there is a palette to measure.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/core/semantic_palette_test.dart`
Expected: FAIL to compile, `Target of URI doesn't exist: 'package:bsharp/core/constants/semantic_color.dart'`

- [ ] **Step 3: Write the enum and palette**

Create `lib/core/constants/semantic_color.dart`:

```dart
enum SemanticColor {
  brandPrimary,
  brandSecondary,
  brandTertiary,
  gradeExcellent,
  gradeVeryGood,
  gradeGood,
  gradeSatisfactory,
  gradeAcceptable,
  gradeFailing,
  attendancePresent,
  attendanceAbsent,
  attendanceLate,
  attendanceExcused,
  statusPresent,
  statusExcused,
  statusUnexcused,
  statusLate,
  statusMixed,
  statusNoData,
}
```

Create `lib/core/constants/semantic_palette.dart`:

```dart
import 'dart:ui';

import 'package:bsharp/core/constants/semantic_color.dart';

abstract final class SemanticPalette {
  static const light = <SemanticColor, Color>{
    SemanticColor.brandPrimary: Color(0xFF2A7F4F),
    SemanticColor.brandSecondary: Color(0xFF1565C0),
    SemanticColor.brandTertiary: Color(0xFFA85F00),
    SemanticColor.gradeExcellent: Color(0xFF2E7D32),
    SemanticColor.gradeVeryGood: Color(0xFF4B7C1F),
    SemanticColor.gradeGood: Color(0xFF8D6E00),
    SemanticColor.gradeSatisfactory: Color(0xFFC44100),
    SemanticColor.gradeAcceptable: Color(0xFFBF360C),
    SemanticColor.gradeFailing: Color(0xFFC62828),
    SemanticColor.attendancePresent: Color(0xFF2E7D32),
    SemanticColor.attendanceAbsent: Color(0xFFC62828),
    SemanticColor.attendanceLate: Color(0xFF8D6E00),
    SemanticColor.attendanceExcused: Color(0xFF1565C0),
    SemanticColor.statusPresent: Color(0xFF2E7D32),
    SemanticColor.statusExcused: Color(0xFF1565C0),
    SemanticColor.statusUnexcused: Color(0xFFC62828),
    SemanticColor.statusLate: Color(0xFFA85F00),
    SemanticColor.statusMixed: Color(0xFFA85F00),
    SemanticColor.statusNoData: Color(0xFF6E6E6E),
  };

  static const dark = <SemanticColor, Color>{
    SemanticColor.brandPrimary: Color(0xFF3FBE7A),
    SemanticColor.brandSecondary: Color(0xFF2196F3),
    SemanticColor.brandTertiary: Color(0xFFFFA726),
    SemanticColor.gradeExcellent: Color(0xFF4CAF50),
    SemanticColor.gradeVeryGood: Color(0xFF8BC34A),
    SemanticColor.gradeGood: Color(0xFFFFC107),
    SemanticColor.gradeSatisfactory: Color(0xFFFF9800),
    SemanticColor.gradeAcceptable: Color(0xFFFF5722),
    SemanticColor.gradeFailing: Color(0xFFF44336),
    SemanticColor.attendancePresent: Color(0xFF4CAF50),
    SemanticColor.attendanceAbsent: Color(0xFFF44336),
    SemanticColor.attendanceLate: Color(0xFFFFC107),
    SemanticColor.attendanceExcused: Color(0xFF2196F3),
    SemanticColor.statusPresent: Color(0xFF4CAF50),
    SemanticColor.statusExcused: Color(0xFF42A5F5),
    SemanticColor.statusUnexcused: Color(0xFFF44336),
    SemanticColor.statusLate: Color(0xFFFFA726),
    SemanticColor.statusMixed: Color(0xFFFFA726),
    SemanticColor.statusNoData: Color(0xFFBDBDBD),
  };

  static Color resolve(SemanticColor token, Brightness brightness) {
    final palette = brightness == Brightness.dark ? dark : light;
    return palette[token]!;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/core/semantic_palette_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/constants/semantic_color.dart lib/core/constants/semantic_palette.dart test/unit/core/semantic_palette_test.dart
git commit -m "feat(theme): add brightness-aware semantic palette

Shared colour helpers returned Material 400/500 tones regardless of
brightness, so the light theme rendered colours chosen for a dark
surface. Introduce a token enum with separate light and dark maps.
The dark map is the existing palette verbatim.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: The contrast guard

**Files:**
- Modify: `test/unit/core/semantic_palette_test.dart`

**Interfaces:**
- Consumes: `SemanticPalette.light`, `SemanticPalette.dark`, `SemanticColor.values`, `AppTheme.light()`, `AppTheme.dark()`
- Produces: nothing consumed by later tasks. This is the regression guard the whole stage exists to install.

- [ ] **Step 1: Write the failing test**

Replace the contents of `test/unit/core/semantic_palette_test.dart`:

```dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:bsharp/core/constants/semantic_color.dart';
import 'package:bsharp/core/constants/semantic_palette.dart';
import 'package:bsharp/presentation/common/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

double _linear(double channel) {
  return channel <= 0.04045
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(Color color) {
  return 0.2126 * _linear(color.r) +
      0.7152 * _linear(color.g) +
      0.0722 * _linear(color.b);
}

double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const minimumRatio = 4.5;

  test('SemanticColor covers every shared token', () {
    expect(SemanticColor.values.length, 19);
    expect(SemanticPalette.light.keys.toSet(), SemanticColor.values.toSet());
    expect(SemanticPalette.dark.keys.toSet(), SemanticColor.values.toSet());
  });

  test('every light token is legible on the light surface', () {
    final surface = AppTheme.light().colorScheme.surface;
    for (final token in SemanticColor.values) {
      final ratio = contrastRatio(SemanticPalette.light[token]!, surface);
      expect(
        ratio,
        greaterThanOrEqualTo(minimumRatio),
        reason: '$token scores ${ratio.toStringAsFixed(2)} on the light surface',
      );
    }
  });

  test('every dark token is legible on the dark surface', () {
    final surface = AppTheme.dark().colorScheme.surface;
    for (final token in SemanticColor.values) {
      final ratio = contrastRatio(SemanticPalette.dark[token]!, surface);
      expect(
        ratio,
        greaterThanOrEqualTo(minimumRatio),
        reason: '$token scores ${ratio.toStringAsFixed(2)} on the dark surface',
      );
    }
  });

  test('every dark token is legible on the wear black surface', () {
    for (final token in SemanticColor.values) {
      final ratio = contrastRatio(
        SemanticPalette.dark[token]!,
        const Color(0xFF000000),
      );
      expect(
        ratio,
        greaterThanOrEqualTo(minimumRatio),
        reason: '$token scores ${ratio.toStringAsFixed(2)} on black',
      );
    }
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `flutter test test/unit/core/semantic_palette_test.dart`
Expected: PASS, 4 tests.

If any token fails, the palette value is wrong, not the test. Darken the light value or lighten the dark value until it clears 4.5, and record the new value in the spec's palette table.

- [ ] **Step 3: Verify the guard actually bites**

Temporarily change `SemanticColor.gradeGood` in `SemanticPalette.light` to `Color(0xFFFFC107)` (the old value).

Run: `flutter test test/unit/core/semantic_palette_test.dart`
Expected: FAIL with `gradeGood scores 1.6x on the light surface`

Revert the change.

- [ ] **Step 4: Commit**

```bash
git add test/unit/core/semantic_palette_test.dart
git commit -m "test(theme): guard semantic palette contrast

Assert every token reaches 4.5:1 against its own theme surface, and
that dark tokens also clear the pure black wear surface. Verified the
guard fails when the old amber is restored.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Grade colours, end to end

Signature change and call sites land together. Splitting them would leave a
commit where `flutter test` does not compile, which the global constraints forbid.

**Files:**
- Modify: `lib/domain/grade_utils.dart:43-51`
- Modify: `test/unit/domain/grade_utils_test.dart:104-137`
- Modify: `lib/presentation/dashboard/widgets/recent_grades_card.dart:94,131`
- Modify: `lib/presentation/grades/widgets/grade_detail_sheet.dart:35`
- Modify: `lib/presentation/grades/widgets/grade_chip.dart:20`
- Modify: `lib/presentation/grades/screens/grades_screen.dart:109,121,161,168`
- Modify: `lib/wear/screens/wear_grades_tile.dart:78`
- Modify: `lib/wear/screens/wear_grades_detail_screen.dart:191`

**Interfaces:**
- Consumes: `SemanticPalette.resolve`, `SemanticColor.grade*`
- Produces: `Color gradeColor(double? value, {required Brightness brightness})`

- [ ] **Step 1: Write the failing test**

Replace the `gradeColor` group in `test/unit/domain/grade_utils_test.dart`:

```dart
  group('gradeColor', () {
    test('maps bands to the dark palette', () {
      const b = Brightness.dark;
      expect(gradeColor(6, brightness: b), SemanticPalette.dark[SemanticColor.gradeExcellent]);
      expect(gradeColor(5.5, brightness: b), SemanticPalette.dark[SemanticColor.gradeExcellent]);
      expect(gradeColor(5, brightness: b), SemanticPalette.dark[SemanticColor.gradeVeryGood]);
      expect(gradeColor(4.5, brightness: b), SemanticPalette.dark[SemanticColor.gradeVeryGood]);
      expect(gradeColor(4, brightness: b), SemanticPalette.dark[SemanticColor.gradeGood]);
      expect(gradeColor(3.5, brightness: b), SemanticPalette.dark[SemanticColor.gradeGood]);
      expect(gradeColor(3, brightness: b), SemanticPalette.dark[SemanticColor.gradeSatisfactory]);
      expect(gradeColor(2.5, brightness: b), SemanticPalette.dark[SemanticColor.gradeSatisfactory]);
      expect(gradeColor(2, brightness: b), SemanticPalette.dark[SemanticColor.gradeAcceptable]);
      expect(gradeColor(1.5, brightness: b), SemanticPalette.dark[SemanticColor.gradeAcceptable]);
      expect(gradeColor(1, brightness: b), SemanticPalette.dark[SemanticColor.gradeFailing]);
      expect(gradeColor(null, brightness: b), SemanticPalette.dark[SemanticColor.gradeSatisfactory]);
    });

    test('maps the same bands to the light palette', () {
      const b = Brightness.light;
      expect(gradeColor(6, brightness: b), SemanticPalette.light[SemanticColor.gradeExcellent]);
      expect(gradeColor(1, brightness: b), SemanticPalette.light[SemanticColor.gradeFailing]);
    });

    test('light and dark differ', () {
      expect(
        gradeColor(4, brightness: Brightness.light),
        isNot(gradeColor(4, brightness: Brightness.dark)),
      );
    });
  });
```

Add these imports to the top of the test file:

```dart
import 'package:bsharp/core/constants/semantic_color.dart';
import 'package:bsharp/core/constants/semantic_palette.dart';
import 'package:flutter/material.dart';
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/domain/grade_utils_test.dart`
Expected: FAIL to compile, `No named parameter with the name 'brightness'`

- [ ] **Step 3: Change the signature**

In `lib/domain/grade_utils.dart`, replace `gradeColor`:

```dart
Color gradeColor(double? value, {required Brightness brightness}) {
  final token = switch (value) {
    null => SemanticColor.gradeSatisfactory,
    >= 5.5 => SemanticColor.gradeExcellent,
    >= 4.5 => SemanticColor.gradeVeryGood,
    >= 3.5 => SemanticColor.gradeGood,
    >= 2.5 => SemanticColor.gradeSatisfactory,
    >= 1.5 => SemanticColor.gradeAcceptable,
    _ => SemanticColor.gradeFailing,
  };
  return SemanticPalette.resolve(token, brightness);
}
```

Add the two palette imports. Remove the `AppColors` import if nothing else in the file uses it.

- [ ] **Step 4: Let the compiler list the call sites**

Run: `flutter analyze lib`
Expected: 6 errors, one per `gradeColor(` call in the Files list above.

- [ ] **Step 5: Update all 6 call sites**

Pass the ambient brightness at each. Where a `theme` local already exists use `theme.brightness`, otherwise `Theme.of(context).brightness`. For example in `grade_chip.dart:20`:

```dart
final color = gradeColor(
  grade.effectiveValue,
  brightness: Theme.of(context).brightness,
);
```

In `grades_screen.dart` all four calls sit inside build methods that already hold a `theme` local; use `theme.brightness` there for consistency with the surrounding code.

- [ ] **Step 6: Verify the tree is clean and green**

Run: `flutter analyze lib test`
Expected: `No issues found!`

Run: `flutter test`
Expected: PASS. A failure here is a colour-literal assertion in an existing widget test; update the expected value to the resolved token and note which test changed.

- [ ] **Step 7: Commit**

```bash
git add lib/domain/grade_utils.dart lib/presentation lib/wear test/unit/domain/grade_utils_test.dart
git commit -m "refactor(grades): resolve grade colour by brightness

gradeColor returned Material 500 tones in both themes, so amber
scored 1.6:1 on the light surface. Take brightness as a required
argument so every call site states its surface and the compiler
finds the ones that do not.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Attendance colours, end to end

**Files:**
- Modify: `lib/domain/attendance_utils.dart:98-107` and `attendanceTypeColor` below it
- Modify: `test/unit/domain/attendance_utils_test.dart`
- Modify: `lib/presentation/attendance/widgets/attendance_day_detail.dart:82,90,244`
- Modify: `lib/presentation/attendance/widgets/attendance_calendar.dart:199,256,260,264,268`
- Modify: `lib/wear/screens/wear_attendance_detail_screen.dart:195`

**Interfaces:**
- Consumes: `SemanticPalette.resolve`, `SemanticColor.status*`, `SemanticColor.attendance*`
- Produces:
  - `Color attendanceStatusColor(AttendanceDayStatus status, {required Brightness brightness})`
  - `Color attendanceTypeColor(AttendanceCountAs countAs, {AttendanceExcuseStatus? excuseStatus, required Brightness brightness})`

- [ ] **Step 1: Read the current `attendanceTypeColor` body**

Run: `sed -n '109,140p' lib/domain/attendance_utils.dart`

Its branch conditions are preserved exactly; only the returned constants become token lookups. Note its second parameter is currently positional-optional (`[AttendanceExcuseStatus? excuseStatus]`) and becomes named, because a required named parameter cannot follow a positional optional one.

- [ ] **Step 2: Write the failing test**

Append to `test/unit/domain/attendance_utils_test.dart`:

```dart
  group('attendanceStatusColor', () {
    test('resolves per brightness', () {
      expect(
        attendanceStatusColor(
          AttendanceDayStatus.present,
          brightness: Brightness.dark,
        ),
        SemanticPalette.dark[SemanticColor.statusPresent],
      );
      expect(
        attendanceStatusColor(
          AttendanceDayStatus.present,
          brightness: Brightness.light,
        ),
        SemanticPalette.light[SemanticColor.statusPresent],
      );
    });

    test('noData differs between themes', () {
      expect(
        attendanceStatusColor(
          AttendanceDayStatus.noData,
          brightness: Brightness.light,
        ),
        isNot(
          attendanceStatusColor(
            AttendanceDayStatus.noData,
            brightness: Brightness.dark,
          ),
        ),
      );
    });
  });
```

Add these imports:

```dart
import 'package:bsharp/core/constants/semantic_color.dart';
import 'package:bsharp/core/constants/semantic_palette.dart';
import 'package:flutter/material.dart';
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/unit/domain/attendance_utils_test.dart`
Expected: FAIL to compile, `No named parameter with the name 'brightness'`

- [ ] **Step 4: Change the signatures**

Replace `attendanceStatusColor`:

```dart
Color attendanceStatusColor(
  AttendanceDayStatus status, {
  required Brightness brightness,
}) {
  final token = switch (status) {
    AttendanceDayStatus.present => SemanticColor.statusPresent,
    AttendanceDayStatus.excused => SemanticColor.statusExcused,
    AttendanceDayStatus.unexcused => SemanticColor.statusUnexcused,
    AttendanceDayStatus.late => SemanticColor.statusLate,
    AttendanceDayStatus.mixed => SemanticColor.statusMixed,
    AttendanceDayStatus.noData => SemanticColor.statusNoData,
  };
  return SemanticPalette.resolve(token, brightness);
}
```

Change `attendanceTypeColor` to
`Color attendanceTypeColor(AttendanceCountAs countAs, {AttendanceExcuseStatus? excuseStatus, required Brightness brightness})`,
keep every existing branch condition unchanged, and replace each returned literal
or `AppColors.attendance*` with
`SemanticPalette.resolve(SemanticColor.attendance<Name>, brightness)`, choosing
the token whose name matches the constant being replaced.

- [ ] **Step 5: Let the compiler list the call sites, then update them**

Run: `flutter analyze lib`
Expected: 6 errors across the three files in the Files list.

Two need care:

- `attendance_calendar.dart:256-268` builds a legend with four calls. Add
  `final brightness = Theme.of(context).brightness;` above the legend and pass it
  to each.
- `attendance_day_detail.dart:244` passes `excuseStatus` positionally. Convert to
  named: `attendanceTypeColor(countAs, excuseStatus: excuseStatus, brightness: Theme.of(context).brightness)`.

- [ ] **Step 6: Verify the tree is clean and green**

Run: `flutter analyze lib test`
Expected: `No issues found!`

Run: `flutter test`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/domain/attendance_utils.dart lib/presentation lib/wear test/unit/domain/attendance_utils_test.dart
git commit -m "refactor(attendance): resolve status colour by brightness

Calendar dots and type chips used dark-surface tones on the light
theme, where four of six fell below even the 3:1 graphical floor.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Unpin the brand accent in `AppTheme`

**Files:**
- Modify: `lib/presentation/common/theme/app_theme.dart:6-11,46-52`
- Test: `test/unit/presentation/app_theme_test.dart` (create)

**Interfaces:**
- Consumes: `SemanticPalette.resolve`, `SemanticColor.brand*`
- Produces: `AppTheme.light()` and `AppTheme.dark()` with brightness-matched `primary`, `secondary`, `tertiary`

- [ ] **Step 1: Write the failing test**

Create `test/unit/presentation/app_theme_test.dart`:

```dart
import 'package:bsharp/core/constants/semantic_color.dart';
import 'package:bsharp/core/constants/semantic_palette.dart';
import 'package:bsharp/presentation/common/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light and dark use different brand accents', () {
    final light = AppTheme.light().colorScheme.primary;
    final dark = AppTheme.dark().colorScheme.primary;
    expect(light, isNot(dark));
  });

  test('accents come from the semantic palette', () {
    expect(
      AppTheme.light().colorScheme.primary,
      SemanticPalette.light[SemanticColor.brandPrimary],
    );
    expect(
      AppTheme.dark().colorScheme.primary,
      SemanticPalette.dark[SemanticColor.brandPrimary],
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/presentation/app_theme_test.dart`
Expected: FAIL, `Expected: not Color(...2E8B57...)` because both themes currently return the same pinned green.

- [ ] **Step 3: Implement**

In `AppTheme.light()`, replace the `ColorScheme.fromSeed` call:

```dart
    final colorScheme = ColorScheme.fromSeed(
      seedColor: SemanticPalette.light[SemanticColor.brandPrimary]!,
      primary: SemanticPalette.light[SemanticColor.brandPrimary],
      secondary: SemanticPalette.light[SemanticColor.brandSecondary],
      tertiary: SemanticPalette.light[SemanticColor.brandTertiary],
    );
```

In `AppTheme.dark()`:

```dart
    final colorScheme = ColorScheme.fromSeed(
      seedColor: SemanticPalette.dark[SemanticColor.brandPrimary]!,
      primary: SemanticPalette.dark[SemanticColor.brandPrimary],
      secondary: SemanticPalette.dark[SemanticColor.brandSecondary],
      tertiary: SemanticPalette.dark[SemanticColor.brandTertiary],
      brightness: Brightness.dark,
    );
```

Add the two palette imports.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/presentation/app_theme_test.dart`
Expected: PASS

- [ ] **Step 5: Re-run the contrast guard**

Run: `flutter test test/unit/core/semantic_palette_test.dart`
Expected: PASS. The light surface may have shifted slightly because the seed changed; if any token now scores below 4.5, darken that light token and update the spec's table.

- [ ] **Step 6: Run the full suite**

Run: `flutter test`
Expected: PASS. Widget tests asserting the old primary need their expected value updated.

- [ ] **Step 7: Commit**

```bash
git add lib/presentation/common/theme/app_theme.dart test/unit/presentation/app_theme_test.dart
git commit -m "fix(theme): stop pinning one accent across both themes

Both AppTheme.light and AppTheme.dark passed the raw brand green as
primary, so the light theme scored 4.05:1 on its own surface. Use the
brightness-matched pair instead.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Retire the superseded constants

**Files:**
- Modify: `lib/core/constants/app_colors.dart`

**Interfaces:**
- Consumes: nothing
- Produces: an `AppColors` holding only what is still referenced

- [ ] **Step 1: Find what still references the old constants**

Run: `grep -rn 'AppColors\.' lib test --include=*.dart | grep -v gradient`
Expected: only the gradient constants and any brand usage outside `AppTheme` remain.

- [ ] **Step 2: Delete the superseded constants**

Remove `gradeExcellent` through `gradeFailing` and `attendancePresent` through `attendanceExcused` from `AppColors`. Keep `primaryGreen`, `seaGreen`, `primaryBlue`, `accentOrange` if the gradient list still uses them, and keep `gradientStart`, `gradientEnd`, `gradientColors`.

- [ ] **Step 2b: Remove the four dead palette tokens**

`AppColors.attendancePresent`, `attendanceAbsent`, `attendanceLate` and
`attendanceExcused` have zero references anywhere in `lib` or `test`, so the
matching `SemanticColor.attendancePresent`, `attendanceAbsent`, `attendanceLate`
and `attendanceExcused` tokens are dead too. Remove those four from
`SemanticColor` and from both maps in `SemanticPalette`. The enum drops from 19
values to 15.

Update the two count assertions in `test/unit/core/semantic_palette_test.dart`
from `19` to `15`.

Nothing consumes these tokens: `attendanceTypeColor` maps to the `status*`
tokens (see Task 4), not these.

If any grep hit remains outside the gradient, migrate it to `SemanticPalette.resolve` before deleting.

- [ ] **Step 3: Verify**

Run: `flutter analyze lib test`
Expected: `No issues found!`

Run: `flutter test`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/core/constants/app_colors.dart
git commit -m "refactor(theme): drop constants superseded by the palette

Grade and attendance constants now live in SemanticPalette with a
light and a dark value each. Keeping duplicates invites the two
sources drifting apart.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Visual verification

**Files:** none modified. This task produces evidence, not code.

**Interfaces:**
- Consumes: the whole stage
- Produces: before/after screenshots proving the light theme changed and the dark theme did not

- [ ] **Step 1: Capture the phone light theme after the change**

```bash
flutter run -d linux --dart-define=MOBIREG_BASE_URL=  # or the configured test provider
```

Navigate to Grades, Attendance and the Dashboard with the app theme set to Light. Screenshot each.

- [ ] **Step 2: Confirm the dark theme is untouched**

```bash
git stash
```

Capture the same three screens in Dark. Then:

```bash
git stash pop
```

Capture them again in Dark. The two sets must be pixel-identical; any difference is a bug in this stage, because dark values were meant to be verbatim.

- [ ] **Step 3: Confirm on the watch emulators**

Both emulators are already configured (`bsharp_wear_round` on port 5554, `bsharp_wear_rect` on 5556). Boot with:

```bash
export ANDROID_HOME=/home/dawid/Android/Sdk QT_QPA_PLATFORM=xcb
$ANDROID_HOME/emulator/emulator -avd bsharp_wear_round -no-snapshot-save -no-boot-anim -no-window -gpu host -feature -Vulkan -port 5554 &
flutter build apk --debug --flavor wear -t lib/main_wear.dart
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-wear-debug.apk
adb -s emulator-5554 shell am start -n pl.brothware.bsharp/.MainActivity
adb -s emulator-5554 exec-out screencap -p > /tmp/wear-grades-light.png
```

Note: `-feature -Vulkan` is required on this machine; the emulator segfaults with hybrid Intel/NVIDIA GPU selection otherwise.

- [ ] **Step 4: Record the outcome**

Attach the screenshots to the PR description. State explicitly whether any dark-theme pixel changed.

---

## Self-Review

**Spec coverage.** Every item in the spec's "The light-theme colour defect" section maps to a task: the palette itself (Task 1), the contrast guard (Task 2), the three helper signatures with their call sites (Tasks 3-4), the pinned accent (Task 5), duplicate removal (Task 6), and the before/after verification the spec asks for in its Stage A description (Task 7).

**Placeholders.** Task 4 Step 4 describes `attendanceTypeColor`'s body by rule rather than literal code, because its branch conditions are read from the file in Step 1 and preserved unchanged; the substitution rule is exact and mechanical. Everything else ships literal code.

**Type consistency.** `gradeColor(double?, {required Brightness brightness})`, `attendanceStatusColor(AttendanceDayStatus, {required Brightness brightness})` and `attendanceTypeColor(AttendanceCountAs, {AttendanceExcuseStatus?, required Brightness brightness})` are used identically in Tasks 3-5. `SemanticPalette.resolve(SemanticColor, Brightness)` and the `light`/`dark` maps are used identically in Tasks 1-5.

**Every commit is green.** An earlier draft split each signature change from its call sites, which would have left two commits where `flutter test` could not compile. Tasks 3 and 4 now each carry their own call-site updates, so the suite passes at every commit. The repository has no pre-commit hook (verified), so nothing enforces this automatically - it is on the implementer.
