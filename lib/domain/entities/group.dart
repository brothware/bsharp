import 'package:freezed_annotation/freezed_annotation.dart';

part 'group.freezed.dart';

@freezed
abstract class Group with _$Group {
  const factory Group({
    required int id,
    required int groupsEduId,
    required String name,
    required String type,
    int? parentId,
    String? attr,
  }) = _Group;
}
