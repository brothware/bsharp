import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.freezed.dart';

@freezed
abstract class ServerSettings with _$ServerSettings {
  const factory ServerSettings({
    required String version,
    required String protocol,
    required String id,
    required DateTime time,
    required int permissions,
  }) = _ServerSettings;
}
