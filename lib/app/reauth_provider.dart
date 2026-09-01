import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reauth_provider.g.dart';

@Riverpod(keepAlive: true)
class PortalReauthRequired extends _$PortalReauthRequired {
  @override
  bool build() => false;
  bool get value => state;
  set value(bool v) => state = v;
}
