import 'package:freezed_annotation/freezed_annotation.dart';

part 'subject.freezed.dart';

@freezed
abstract class Subject with _$Subject {
  const factory Subject({
    required int id,
    required String name,
    required String abbr,
    int? subjectsEduId,
  }) = _Subject;
}
