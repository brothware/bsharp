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
    @Default('') String password,
    String? legacyPasswordHash,
    String? schoolName,
    @Default([]) List<AccountStudent> students,
  }) = _ProviderAccount;

  factory ProviderAccount.fromJson(Map<String, dynamic> json) =>
      _$ProviderAccountFromJson(migrateLegacyJson(json));

  static Map<String, dynamic> migrateLegacyJson(Map<String, dynamic> json) {
    if (!json.containsKey('password') && json.containsKey('passwordHash')) {
      return Map<String, dynamic>.of(json)
        ..['legacyPasswordHash'] = json['passwordHash']
        ..['password'] = '';
    }
    return json;
  }
}

extension ProviderAccountReauth on ProviderAccount {
  bool get needsReauth => password.isEmpty && legacyPasswordHash != null;
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
