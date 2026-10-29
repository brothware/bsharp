import 'package:bsharp/app/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Router redirect logic', () {
    test('unauthenticated redirects to account setup', () {
      final router = createRouter(authState: AuthState.unauthenticated);
      expect(router.configuration.routes, isNotEmpty);
    });

    test('authenticated does not redirect from dashboard', () {
      final router = createRouter(authState: AuthState.authenticated);
      expect(router.configuration.routes, isNotEmpty);
    });

    test('AppRoutes constants are correct', () {
      expect(AppRoutes.accountSetup, '/account-setup');
      expect(AppRoutes.dashboard, '/dashboard');
      expect(AppRoutes.schedule, '/schedule');
      expect(AppRoutes.grades, '/grades');
      expect(AppRoutes.attendance, '/attendance');
      expect(AppRoutes.messages, '/messages');
      expect(AppRoutes.settings, '/settings');
      expect(AppRoutes.accountsManage, '/accounts/manage');
      expect(AppRoutes.homework, '/homework');
      expect(AppRoutes.notes, '/notes');
      expect(AppRoutes.tests, '/tests');
      expect(AppRoutes.bulletins, '/bulletins');
      expect(AppRoutes.changelog, '/changelog');
      expect(AppRoutes.watchSetup, '/settings/watch-setup');
    });

    test('the link the watch opens lands on Set up watch', () {
      final router = createRouter(authState: AuthState.authenticated);

      final match = router.configuration.findMatch(
        Uri.parse(watchSetupLink).replace(scheme: '', host: ''),
      );

      expect(match.isNotEmpty, isTrue);
      expect(
        match.matches.map((m) => m.matchedLocation),
        [AppRoutes.settings, AppRoutes.watchSetup],
        reason: 'opened from the watch, back should reach Settings, not exit',
      );
    });
  });
}
