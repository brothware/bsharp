import 'package:freezed_annotation/freezed_annotation.dart';

part 'provider_account.freezed.dart';
part 'provider_account.g.dart';

@freezed
abstract class ProviderAccount with _$ProviderAccount {
  const factory ProviderAccount({
    required String id,
    required String providerType,
    required String slug,
    required String login,
    required String passwordHash,
    String? schoolName,
    @Default([]) List<AccountStudent> students,
  }) = _ProviderAccount;

  factory ProviderAccount.fromJson(Map<String, dynamic> json) =>
      _$ProviderAccountFromJson(json);
}

@freezed
abstract class AccountStudent with _$AccountStudent {
  const factory AccountStudent({
    required int id,
    required String name,
    required String surname,
  }) = _AccountStudent;

  factory AccountStudent.fromJson(Map<String, dynamic> json) =>
      _$AccountStudentFromJson(json);
}
