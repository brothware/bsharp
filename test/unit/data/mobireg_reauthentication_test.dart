import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/data/providers/mobireg/mobireg_data_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hands out a real [Ref] so the provider can be driven the way the app drives
/// it, without standing up the whole sync.
final _refProvider = Provider<Ref>((ref) => ref);

/// A sync re-authenticates before every run, so [MobiregDataProvider] holds on
/// to its portal session when the same account comes back. These cases pin the
/// other half of that rule: a different account must still be noticed.
///
/// Each case ends on credentials the portal cannot use (the plaintext password
/// is gone, only a legacy hash survives), because that is the one state the
/// provider reports without reaching the network: it raises
/// `portalReauthRequired` and stops. If the provider wrongly kept the earlier
/// credentials it would sail past that point instead, and the flag stays false.
void main() {
  group('MobiregDataProvider.authenticate', () {
    late ProviderContainer container;
    late Ref ref;

    setUp(() {
      container = ProviderContainer();
      ref = container.read(_refProvider);
    });

    tearDown(() => container.dispose());

    test('notices the password it had is gone', () async {
      final provider = MobiregDataProvider();
      await provider.authenticate(
        school: 'sp1',
        login: 'parent',
        password: 'secret',
      );

      await provider.authenticate(
        school: 'sp1',
        login: 'parent',
        password: '',
        legacyPasswordHash: 'a' * 32,
      );
      await provider.loadMessages(ref);

      expect(container.read(portalReauthRequiredProvider), isTrue);
    });

    test('notices a switch to another school', () async {
      final provider = MobiregDataProvider();
      await provider.authenticate(
        school: 'sp1',
        login: 'parent',
        password: 'secret',
      );

      await provider.authenticate(
        school: 'sp2',
        login: 'parent',
        password: '',
        legacyPasswordHash: 'a' * 32,
      );
      await provider.loadMessages(ref);

      expect(container.read(portalReauthRequiredProvider), isTrue);
    });

    test('notices a switch to another login', () async {
      final provider = MobiregDataProvider();
      await provider.authenticate(
        school: 'sp1',
        login: 'parent',
        password: 'secret',
      );

      await provider.authenticate(
        school: 'sp1',
        login: 'other',
        password: '',
        legacyPasswordHash: 'a' * 32,
      );
      await provider.loadMessages(ref);

      expect(container.read(portalReauthRequiredProvider), isTrue);
    });
  });
}
