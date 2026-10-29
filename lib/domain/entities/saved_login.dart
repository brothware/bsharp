import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_login.freezed.dart';

@freezed
abstract class SavedLogin with _$SavedLogin {
  const factory SavedLogin({
    required String school,
    required String login,
    required String password,
  }) = _SavedLogin;
}
