import 'package:bsharp/app/child_provider.dart';
import 'package:bsharp/data/providers/mobireg_data_provider.dart';
import 'package:bsharp/data/services/sync_data_parser.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/presentation/attendance/providers/attendance_providers.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/presentation/messages/providers/messages_providers.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void applySyncData(Ref ref, Map<String, dynamic> data) {
  final parser = SyncDataParser();
  final syncData = parser.parse(data);

  if (syncData.students.isNotEmpty) {
    ref.read(studentsProvider.notifier).value = syncData.students;
  }
  if (syncData.teachers.isNotEmpty) {
    ref.read(teachersProvider.notifier).value = syncData.teachers;
  }
  if (syncData.subjects.isNotEmpty) {
    ref.read(subjectsProvider.notifier).value = syncData.subjects;
  }
  if (syncData.terms.isNotEmpty) {
    ref.read(termsProvider.notifier).value = syncData.terms;
  }
  if (syncData.rooms.isNotEmpty) {
    ref.read(roomsProvider.notifier).value = syncData.rooms;
  }
  if (syncData.events.isNotEmpty) {
    ref.read(eventsProvider.notifier).value = syncData.events;
  }
  if (syncData.eventTypes.isNotEmpty) {
    ref.read(eventTypesProvider.notifier).value = syncData.eventTypes;
  }
  if (syncData.eventTypeTeachers.isNotEmpty) {
    ref.read(eventTypeTeachersProvider.notifier).value =
        syncData.eventTypeTeachers;
  }
  if (syncData.eventTypeTerms.isNotEmpty) {
    ref.read(eventTypeTermsProvider.notifier).value = syncData.eventTypeTerms;
  }
  if (syncData.eventSubjects.isNotEmpty) {
    ref.read(eventSubjectsProvider.notifier).value = syncData.eventSubjects;
  }
  if (syncData.eventEvents.isNotEmpty) {
    ref.read(eventEventsProvider.notifier).value = syncData.eventEvents;
  }
  if (syncData.marks.isNotEmpty) {
    ref.read(marksProvider.notifier).value = syncData.marks;
  }
  if (syncData.markGroups.isNotEmpty) {
    ref.read(markGroupsProvider.notifier).value = syncData.markGroups;
  }
  if (syncData.markKinds.isNotEmpty) {
    ref.read(markKindsProvider.notifier).value = syncData.markKinds;
  }
  if (syncData.markScales.isNotEmpty) {
    ref.read(markScalesProvider.notifier).value = syncData.markScales;
  }
  if (syncData.markGroupGroups.isNotEmpty) {
    ref.read(markGroupGroupsProvider.notifier).value = syncData.markGroupGroups;
  }
  if (syncData.attendances.isNotEmpty) {
    ref.read(attendancesProvider.notifier).value = syncData.attendances;
  }
  if (syncData.attendanceTypes.isNotEmpty) {
    ref.read(attendanceTypesProvider.notifier).value = syncData.attendanceTypes;
  }
}

void applyPortalBulletins(Ref ref, List<dynamic> items) {
  ref.read(bulletinsProvider.notifier).value = parseBulletins(items);
}

void applyPortalTests(Ref ref, List<dynamic> items) {
  ref.read(testsProvider.notifier).value = parseTests(items);
}

void applyPortalHomeworks(Ref ref, List<dynamic> items) {
  ref.read(homeworksProvider.notifier).value = parseHomeworks(items);
}

void applyPortalReprimands(Ref ref, List<dynamic> items) {
  ref.read(reprimandsProvider.notifier).value = parseReprimands(items);
}

void applyPortalChangelog(
  Ref ref,
  String type,
  List<dynamic> items,
) {
  final parsed = parseChangelog(items);
  if (type == 'mark') {
    ref.read(gradeChangelogProvider.notifier).value = parsed;
  } else if (type == 'attendance') {
    ref.read(attendanceChangelogProvider.notifier).value = parsed;
  }
}

void applyMessages(Ref ref, String folder, List<dynamic> data) {
  final messages = parsePocztaMessages(data);
  switch (folder) {
    case 'inbox':
      ref.read(inboxProvider.notifier).value = messages;
    case 'sent':
      ref.read(sentProvider.notifier).value = messages;
    case 'trash':
      ref.read(trashProvider.notifier).value = messages;
  }
}

List<PortalBulletin> parseBulletins(List<dynamic> data) {
  final result = <PortalBulletin>[];
  for (final item in data) {
    if (item is! Map<String, dynamic>) continue;
    try {
      result.add(
        PortalBulletin(
          id: item['id'] as int,
          title: (item['title'] ?? '') as String,
          content: '',
          date: (item['dateTime'] ?? '') as String,
          author: (item['author'] ?? '') as String,
          isRead: item['read'] != null,
        ),
      );
    } on Object {
      continue;
    }
  }
  return result;
}

List<PortalChangelog> parseChangelog(List<dynamic> data) {
  final result = <PortalChangelog>[];
  for (final item in data) {
    if (item is! Map<String, dynamic>) continue;
    try {
      result.add(
        PortalChangelog(
          type: (item['type'] ?? '') as String,
          dateTime: (item['dateTime'] ?? '') as String,
          subjectName: (item['subjectName'] ?? '') as String,
          user: (item['user'] ?? '') as String,
          newName: (item['newName'] ?? '') as String,
          newAdditionalInfo: (item['newAdditionalInfo'] ?? '') as String,
          action: (item['action'] ?? '') as String,
        ),
      );
    } on Object {
      continue;
    }
  }
  return result;
}

List<PortalReprimand> parseReprimands(List<dynamic> data) {
  final result = <PortalReprimand>[];
  for (final item in data) {
    if (item is! Map<String, dynamic>) continue;
    try {
      result.add(
        PortalReprimand(
          id: item['id'] as int,
          date: (item['date'] ?? '') as String,
          teacherName: (item['teacherName'] ?? '') as String,
          content: (item['content'] ?? '') as String,
          type: item['type'] as int,
        ),
      );
    } on Object {
      continue;
    }
  }
  return result;
}

List<PortalTest> parseTests(List<dynamic> data) {
  final result = <PortalTest>[];
  for (final item in data) {
    if (item is! Map<String, dynamic>) continue;
    try {
      final dateTime = item['dateTime'] as String?;
      final date = dateTime != null
          ? dateTime.substring(0, 10)
          : (item['date'] ?? '') as String;
      result.add(
        PortalTest(
          id: item['id'] as int,
          subjectName: (item['subjectName'] ?? '') as String,
          date: date,
          title: item['title'] as String?,
          description: item['description'] as String?,
        ),
      );
    } on Object {
      continue;
    }
  }
  return result;
}

List<PortalHomework> parseHomeworks(List<dynamic> data) {
  final result = <PortalHomework>[];
  for (final item in data) {
    if (item is! Map<String, dynamic>) continue;
    try {
      result.add(
        PortalHomework(
          id: item['id'] as int,
          subjectName: (item['subjectName'] ?? '') as String,
          date: (item['date'] ?? '') as String,
          dueDate: (item['dueDate'] ?? item['date'] ?? '') as String,
          content: (item['content'] ?? item['description'] ?? '') as String,
        ),
      );
    } on Object {
      continue;
    }
  }
  return result;
}
