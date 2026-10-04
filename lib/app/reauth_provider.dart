import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reauth_provider.g.dart';

@Riverpod(keepAlive: true)
class ReauthRequired extends _$ReauthRequired {
  @override
  bool build() => false;
  bool get value => state;
  set value(bool v) => state = v;
}
