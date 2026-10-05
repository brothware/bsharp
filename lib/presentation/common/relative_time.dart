import 'package:bsharp/l10n/strings.g.dart';

const _minutesPerHour = 60;
const _hoursPerDay = 24;
const _twoDigits = 2;

String formatRelativeTime(DateTime time, {DateTime? now}) {
  final elapsed = (now ?? DateTime.now()).difference(time);
  if (elapsed.inMinutes < 1) {
    return t.common.agoJustNow;
  }
  if (elapsed.inMinutes < _minutesPerHour) {
    return t.common.agoMinutes(n: elapsed.inMinutes);
  }
  if (elapsed.inHours < _hoursPerDay) {
    return t.common.agoHours(n: elapsed.inHours);
  }
  return '${_pad(time.day)}.${_pad(time.month)} '
      '${_pad(time.hour)}:${_pad(time.minute)}';
}

String _pad(int value) => value.toString().padLeft(_twoDigits, '0');
