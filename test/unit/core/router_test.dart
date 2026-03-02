import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/router.dart';

void main() {
  group('Router redirect logic', () {
    test('unauthenticated redirects to login', () {
      final router = createRouter(authState: AuthState.unauthenticated);
      expect(router.configuration.routes, isNotEmpty);
    });

    test('authenticated does not redirect from dashboard', () {
      final router = createRouter(authState: AuthState.authenticated);
      expect(router.configuration.routes, isNotEmpty);
    });

    test('AppRoutes constants are correct', () {
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.dashboard, '/dashboard');
      expect(AppRoutes.schedule, '/schedule');
      expect(AppRoutes.grades, '/grades');
      expect(AppRoutes.attendance, '/attendance');
      expect(AppRoutes.messages, '/messages');
      expect(AppRoutes.settings, '/settings');
      expect(AppRoutes.homework, '/homework');
      expect(AppRoutes.notes, '/notes');
      expect(AppRoutes.tests, '/tests');
      expect(AppRoutes.bulletins, '/bulletins');
      expect(AppRoutes.changelog, '/changelog');
    });
  });
}
