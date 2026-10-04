import 'package:bsharp/data/providers/mobireg/parsers/json_fields.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:flutter/foundation.dart';

const _view = 'users';
const _unknownUsersEduId = 0;
const Sex _unknownSex = Sex.female;
const _enabledModuleFlag = 1;

@immutable
class MobiregAccount {
  const MobiregAccount({
    required this.students,
    required this.schoolName,
    required this.messagingUrl,
    required this.messagesToken,
    required this.enabledModules,
  });

  final List<Student> students;
  final String? schoolName;
  final String? messagingUrl;
  final String? messagesToken;
  final Set<String>? enabledModules;
}

MobiregAccount parseAccount(Map<String, dynamic> data) {
  final students = objectsOf(data['pupils'], _view).map((pupil) {
    return Student(
      id: intField(pupil, 'id', _view),
      usersEduId: _unknownUsersEduId,
      name: stringField(pupil, 'firstname', _view),
      surname: stringField(pupil, 'lastname', _view),
      sex: _unknownSex,
    );
  }).toList();
  return MobiregAccount(
    students: students,
    schoolName: _firstSchoolNameLine(data['schoolName']),
    messagingUrl: optionalStringField(data, 'messagingUrl'),
    messagesToken: optionalStringField(data, 'messagesToken'),
    enabledModules: _enabledModules(data['appConfig']),
  );
}

String? _firstSchoolNameLine(Object? schoolName) {
  if (schoolName is! List || schoolName.isEmpty) {
    return null;
  }
  final first = schoolName.first;
  if (first is! String) {
    throw FormatException('View $_view: "schoolName" is not strings', first);
  }
  return first;
}

Set<String>? _enabledModules(Object? appConfig) {
  if (appConfig is! Map<String, dynamic>) {
    return null;
  }
  final modules = appConfig['modules'];
  if (modules is! Map<String, dynamic>) {
    return null;
  }
  return {
    for (final entry in modules.entries)
      if (entry.value == _enabledModuleFlag) entry.key,
  };
}
