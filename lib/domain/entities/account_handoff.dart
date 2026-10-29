import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_handoff.freezed.dart';

@freezed
abstract class AccountHandoff with _$AccountHandoff {
  const factory AccountHandoff({
    required String providerType,
    required String school,
    required String login,
    required String password,
  }) = _AccountHandoff;
}
