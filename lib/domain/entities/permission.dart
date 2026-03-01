import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission.freezed.dart';

@freezed
abstract class PermissionGroup with _$PermissionGroup {
  const factory PermissionGroup({
    required int id,
    required int permissionGroupsId,
    int? parentId,
    required String name,
    String? description,
    String? additionalDescription,
    String? image,
  }) = _PermissionGroup;
}

@freezed
abstract class Permission with _$Permission {
  const factory Permission({
    required int id,
    required int permissionGroupsId,
    required int usersId,
    int? eduId,
    int? quantitativeLimit,
    DateTime? grantTime,
    DateTime? expireTime,
    int? source,
  }) = _Permission;
}
