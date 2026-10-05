import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, String> enKeys;
  late Map<String, Map<String, String>> allLocales;

  setUpAll(() {
    final l10nDir = Directory('lib/l10n');
    final enFile = File('${l10nDir.path}/en.i18n.json');
    final enJson =
        jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
    enKeys = _flatten(enJson);

    allLocales = {};
    for (final file in l10nDir.listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      if (!name.endsWith('.i18n.json') || name == 'en.i18n.json') continue;
      final lang = name.replaceAll('.i18n.json', '');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      allLocales[lang] = _flatten(json);
    }
  });

  test('all locales have every key from English', () {
    final missing = <String, List<String>>{};

    for (final entry in allLocales.entries) {
      final lang = entry.key;
      final keys = entry.value;
      final missingKeys = enKeys.keys.where((k) {
        if (keys.containsKey(k)) return false;
        if (k.contains('(context=')) {
          final base = k.replaceAll(RegExp(r'\(context=\w+\)'), '');
          return !keys.keys.any((lk) => lk.startsWith(base));
        }
        return true;
      }).toList();
      if (missingKeys.isNotEmpty) {
        missing[lang] = missingKeys;
      }
    }

    if (missing.isNotEmpty) {
      final buf = StringBuffer('Missing keys:\n');
      for (final entry
          in missing.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
        buf.writeln('  ${entry.key}: ${entry.value.join(', ')}');
      }
      fail(buf.toString());
    }
  });

  test('every attachment string is translated in every locale', () {
    final composeKeys = enKeys.keys
        .where((key) => key.startsWith('compose.'))
        .toList();
    expect(composeKeys, isNotEmpty);
    final problems = <String>[];

    for (final MapEntry(key: lang, value: keys) in allLocales.entries) {
      for (final key in composeKeys) {
        final english = enKeys[key]!;
        final value = keys[key];
        if (value == null) {
          problems.add('$lang $key: missing');
          continue;
        }
        if (!setEquals(_placeholdersOf(value), _placeholdersOf(english))) {
          problems.add('$lang $key: placeholders differ');
        }
        final isGenuinelyIdentical =
            _sizeUnitKeys.contains(key) &&
            !_localesWithOwnSizeUnits.contains(lang);
        if (value == english && !isGenuinelyIdentical) {
          problems.add('$lang $key: still English');
        }
      }
    }

    expect(problems, isEmpty);
  });

  test('no locale has untranslated English values', () {
    const skipKeys = <String>{
      'messages.replyPrefix',
      'grades.weightPrefix',
      'grades.simpleAverageLabel',
      'settings.version',
      'sync.messagesCount',
      'gradeCategories.test',
      'subjectNames.tuba',
      'subjectNames.altowka',
      'subjectNames.oboj',
      'subjectNames.fortepian',
      'subjectNames.puzon',
      'subjectNames.orkiestra',
      'subjectNames.klarnet',
      'subjectNames.jezykLacinski',
      'subjectNames.religia',
      'subjectNames.wiolonczela',
      'subjectNames.trabka',
      'attendanceTypes.popis',
      'termNames.trymestr',
      'termNames.semestr',
      'subjectNames.saksofon',
      'subjectNames.harfa',
      'subjectNames.organy',
      'subjectNames.perkusja',
      'attendance.month.apr',
      'attendance.month.aug',
      'attendance.month.sep',
      'attendance.month.nov',
      'attendance.month.dec',
      'attendance.total',
      'attendance.calendar',
      'common.error',
      'auth.password',
      'auth.username',
      'settings.themeSystem',
      'settings.languageSystem',
      'settings.data',
      'settings.account',
      'settings.licenses',
      'settings.notifications',
      'nav.dashboard',
      'nav.messages',
      'setup.schoolStep',
      'setup.credentialsStep',
      'setup.studentStep',
      'messages.inbox',
      'messages.attachments',
      'messages.send',
      'gradeNames.poprawne',
      'gradeCategories.projekt',
      'gradeCategories.kartkowka',
      'childMode.mode',
      'schedule.date',
      'schedule.customEvent.description',
      'grades.date',
      'grades.description',
      'messages.title',
      'messages.messageLabel',
      'messages.message(context=one)',
      'messages.message(context=other)',
      'messages.italic',
      'messages.underline',
      'notes.info',
      'notes.infoTab',
      'homework.title',
      'receiverRoles.rodzic',
      'attendanceTypes.koncert',
      'attendanceTypes.warsztaty',
      'settings.syncSection',
      'settings.title',
      'notification.homeworkName',
      'notification.messagesName',
      'notification.generalName',
      'subjectNames.gitara',
      'subjectNames.skrzypce',
      'gradeCategories.recytacja',
      'gradeCategories.pracaDomowa',
      'support.buyMeACoffee',
      'wearDashboard.moreBadge',
      ..._sizeUnitKeys,
    };

    final untranslated = <String, List<String>>{};

    for (final entry in allLocales.entries) {
      final lang = entry.key;
      final keys = entry.value;
      final stale = <String>[];

      for (final enEntry in enKeys.entries) {
        final key = enEntry.key;
        final enVal = enEntry.value;
        if (skipKeys.contains(key)) continue;
        if (enVal.length <= 3) continue;
        if (keys[key] == enVal) {
          stale.add(key);
        }
      }

      if (stale.isNotEmpty) {
        untranslated[lang] = stale;
      }
    }

    if (untranslated.isNotEmpty) {
      final buf = StringBuffer('Untranslated keys (still English):\n');
      for (final entry
          in untranslated.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key))) {
        buf.writeln(
          '  ${entry.key} (${entry.value.length}): ${entry.value.take(5).join(', ')}${entry.value.length > 5 ? '...' : ''}',
        );
      }
      fail(buf.toString());
    }
  });
}

const _sizeUnitKeys = {
  'compose.sizeBytes',
  'compose.sizeKilobytes',
  'compose.sizeMegabytes',
};

const _localesWithOwnSizeUnits = {'be', 'bg', 'fi', 'fr', 'mk', 'uk'};

final _placeholder = RegExp(r'\$\{(\w+)\}');

Set<String> _placeholdersOf(String value) {
  return _placeholder.allMatches(value).map((match) => match[1]!).toSet();
}

Map<String, String> _flatten(Map<String, dynamic> json, [String prefix = '']) {
  final result = <String, String>{};
  for (final entry in json.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    if (entry.value is Map<String, dynamic>) {
      result.addAll(_flatten(entry.value as Map<String, dynamic>, key));
    } else if (entry.value is String) {
      result[key] = entry.value as String;
    }
  }
  return result;
}
