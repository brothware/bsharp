import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/core/network/api_client_factory.dart';
import 'package:bsharp/data/data_sources/remote/auth_service.dart';
import 'package:bsharp/data/data_sources/remote/mobile_sync_data_source.dart';

class SetupApiState {
  SetupApiState({required this.syncDataSource, required this.authService});

  final MobileSyncDataSource syncDataSource;
  final AuthService authService;
}

typedef SetupApiParams = ({
  String school,
  String parentLogin,
  String parentPassHash,
});

final setupApiProvider = Provider.family<SetupApiState, SetupApiParams>((
  ref,
  params,
) {
  final factory = ApiClientFactory(
    school: params.school,
    parentLogin: params.parentLogin,
    parentPassHash: params.parentPassHash,
  );

  return SetupApiState(
    syncDataSource: MobileSyncDataSource(
      client: factory.createMobileSyncClient(),
    ),
    authService: AuthService(webLoginClient: factory.createWebLoginClient()),
  );
});
