import 'package:go_router/go_router.dart';
import 'package:bsharp/presentation/attendance/screens/attendance_screen.dart';
import 'package:bsharp/presentation/auth/screens/login_screen.dart';
import 'package:bsharp/presentation/auth/screens/setup_wizard_screen.dart';
import 'package:bsharp/presentation/bulletins/screens/bulletins_screen.dart';
import 'package:bsharp/presentation/changelog/screens/changelog_screen.dart';
import 'package:bsharp/presentation/common/widgets/main_shell.dart';
import 'package:bsharp/presentation/dashboard/screens/dashboard_screen.dart';
import 'package:bsharp/presentation/grades/screens/grades_screen.dart';
import 'package:bsharp/presentation/homework/screens/homework_screen.dart';
import 'package:bsharp/presentation/messages/screens/messages_screen.dart';
import 'package:bsharp/presentation/notes/screens/notes_screen.dart';
import 'package:bsharp/presentation/schedule/screens/schedule_screen.dart';
import 'package:bsharp/presentation/settings/screens/settings_screen.dart';
import 'package:bsharp/presentation/tests/screens/tests_screen.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const setup = '/setup';
  static const dashboard = '/dashboard';
  static const schedule = '/schedule';
  static const grades = '/grades';
  static const attendance = '/attendance';
  static const messages = '/messages';
  static const settings = '/settings';
  static const homework = '/homework';
  static const notes = '/notes';
  static const tests = '/tests';
  static const bulletins = '/bulletins';
  static const changelog = '/changelog';
}

enum AuthState { unauthenticated, needsSetup, authenticated }

GoRouter createRouter({required AuthState authState}) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    redirect: (context, state) {
      final location = state.uri.path;
      final isOnLogin = location == AppRoutes.login;
      final isOnSetup = location.startsWith(AppRoutes.setup);

      return switch (authState) {
        AuthState.unauthenticated when !isOnLogin => AppRoutes.login,
        AuthState.needsSetup when !isOnSetup => AppRoutes.setup,
        AuthState.authenticated when isOnLogin || isOnSetup =>
          AppRoutes.dashboard,
        _ => null,
      };
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.setup,
        builder: (context, state) => const SetupWizardScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.schedule,
                builder: (context, state) => const ScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.grades,
                builder: (context, state) => const GradesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.attendance,
                builder: (context, state) => const AttendanceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homework,
                builder: (context, state) => const HomeworkScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.notes,
                builder: (context, state) => const NotesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tests,
                builder: (context, state) => const TestsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.bulletins,
                builder: (context, state) => const BulletinsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.changelog,
                builder: (context, state) => const ChangelogScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.messages,
        builder: (context, state) => const MessagesScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
