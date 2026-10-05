import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/relative_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  final now = DateTime(2026, 10, 5, 12, 30);

  test('under a minute reads as just now', () {
    expect(
      formatRelativeTime(now.subtract(const Duration(seconds: 30)), now: now),
      t.common.agoJustNow,
    );
  });

  test('under an hour counts minutes', () {
    expect(
      formatRelativeTime(now.subtract(const Duration(minutes: 5)), now: now),
      t.common.agoMinutes(n: 5),
    );
  });

  test('under a day counts hours', () {
    expect(
      formatRelativeTime(now.subtract(const Duration(hours: 3)), now: now),
      t.common.agoHours(n: 3),
    );
  });

  test('older than a day shows a padded day, month and time', () {
    expect(
      formatRelativeTime(DateTime(2026, 10, 3, 7, 4), now: now),
      '03.10 07:04',
    );
  });
}
