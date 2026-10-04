import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/core/network/api_client_factory.dart';
import 'package:bsharp/data/providers/mobireg/mobireg_data_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _refProvider = Provider<Ref>((ref) => ref);

class _OfflineFactory extends ApiClientFactory {
  _OfflineFactory(this._requests, String school)
    : super(school: school, parentLogin: '', parentPassHash: '');

  final List<String> _requests;

  @override
  Dio createAppApiClient() => Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _requests.add(options.path);
          handler.reject(
            DioException(requestOptions: options, message: 'offline'),
          );
        },
      ),
    );
}

void main() {
  group('MobiregDataProvider.authenticate', () {
    late ProviderContainer container;
    late Ref ref;
    late List<String> requests;
    late MobiregDataProvider provider;

    setUp(() {
      container = ProviderContainer();
      ref = container.read(_refProvider);
      requests = [];
      provider = MobiregDataProvider(
        clientFactory: (school) => _OfflineFactory(requests, school),
      );
    });

    tearDown(() => container.dispose());

    test('notices the password it had is gone', () async {
      await provider.authenticate(
        school: 'sp1',
        login: 'parent',
        password: 'secret',
      );

      await provider.authenticate(school: 'sp1', login: 'parent', password: '');
      await provider.loadSchoolData(ref, studentId: 1);

      expect(container.read(reauthRequiredProvider), isTrue);
      expect(requests, isEmpty);
    });

    test('notices a switch to another school', () async {
      await provider.authenticate(
        school: 'sp1',
        login: 'parent',
        password: 'secret',
      );

      await provider.authenticate(school: 'sp2', login: 'parent', password: '');
      await provider.loadSchoolData(ref, studentId: 1);

      expect(container.read(reauthRequiredProvider), isTrue);
      expect(requests, isEmpty);
    });

    test('notices a switch to another login', () async {
      await provider.authenticate(
        school: 'sp1',
        login: 'parent',
        password: 'secret',
      );

      await provider.authenticate(school: 'sp1', login: 'other', password: '');
      await provider.loadMessages(ref);

      expect(container.read(reauthRequiredProvider), isTrue);
      expect(requests, isEmpty);
    });
  });
}
