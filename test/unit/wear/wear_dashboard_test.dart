import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/app/providers/more_providers.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/screens/wear_dashboard.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ResolvedEvent _resolvedEvent({
  int id = 1,
  DateTime? date,
  int number = 1,
  String startTime = '08:00:00',
  String endTime = '08:45:00',
  String? subjectName,
  String? roomName,
  bool isCancelled = false,
}) {
  final now = DateTime.now();
  return ResolvedEvent(
    id: id,
    date: date ?? DateTime(now.year, now.month, now.day),
    number: number,
    startTime: startTime,
    endTime: endTime,
    subjectName: subjectName,
    roomName: roomName,
    isCancelled: isCancelled,
  );
}

String _isoDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

Widget _buildDashboard({
  required SharedPreferences prefs,
  List<ResolvedEvent> resolvedEvents = const [],
  WearScreenShape shape = WearScreenShape.rectangular,
  List<PocztaMessage> inbox = const [],
  List<PortalTest> tests = const [],
  List<PortalReprimand> reprimands = const [],
  List<PortalBulletin> bulletins = const [],
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      wearScreenShapeProvider.overrideWith((_) => shape),
      resolvedEventsProvider.overrideWithBuild((ref, _) => resolvedEvents),
      inboxProvider.overrideWithBuild((ref, _) => inbox),
      testsProvider.overrideWithBuild((ref, _) => tests),
      reprimandsProvider.overrideWithBuild((ref, _) => reprimands),
      bulletinsProvider.overrideWithBuild((ref, _) => bulletins),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: WearDisplayScope(
          display: WearDisplay(shape: shape, sizeDp: const Size(400, 400)),
          child: const WearDashboard(),
        ),
      ),
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  for (final shape in WearScreenShape.values) {
    group('WearDashboard (${shape.name})', () {
      testWidgets('shows NOW for a lesson in progress with its room', (
        tester,
      ) async {
        final now = TimeOfDay.now();
        final start = TimeOfDay(
          hour: now.hour,
          minute: now.minute,
        ).replacing(minute: (now.minute - 5).clamp(0, 59));
        await tester.pumpWidget(
          _buildDashboard(
            prefs: prefs,
            shape: shape,
            resolvedEvents: [
              _resolvedEvent(
                subjectName: 'Math',
                roomName: 'Room 12',
                startTime:
                    '${start.hour.toString().padLeft(2, '0')}:'
                    '${start.minute.toString().padLeft(2, '0')}:00',
                endTime: '23:59:00',
              ),
            ],
          ),
        );
        await tester.pump();

        expect(find.text('NOW'), findsOneWidget);
        expect(find.text('Room 12'), findsOneWidget);
      });

      testWidgets('shows NEXT for an upcoming lesson with its room', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildDashboard(
            prefs: prefs,
            shape: shape,
            resolvedEvents: [
              _resolvedEvent(
                subjectName: 'Physics',
                roomName: 'Room 5',
                startTime: '23:58:00',
                endTime: '23:59:00',
              ),
            ],
          ),
        );
        await tester.pump();

        expect(find.text('NEXT'), findsOneWidget);
        expect(find.text('Room 5'), findsOneWidget);
      });

      testWidgets('shows TOMORROW once all of today ended', (tester) async {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        await tester.pumpWidget(
          _buildDashboard(
            prefs: prefs,
            shape: shape,
            resolvedEvents: [
              _resolvedEvent(startTime: '00:00:00', endTime: '00:01:00'),
              _resolvedEvent(
                id: 2,
                date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
                subjectName: 'Chemistry',
                roomName: 'Room 3',
              ),
            ],
          ),
        );
        await tester.pump();

        expect(find.text('TOMORROW'), findsOneWidget);
        expect(find.text('Room 3'), findsOneWidget);
      });

      testWidgets('shows NO LESSONS when today is empty', (tester) async {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        await tester.pumpWidget(
          _buildDashboard(
            prefs: prefs,
            shape: shape,
            resolvedEvents: [
              _resolvedEvent(
                date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
                subjectName: 'Chemistry',
                roomName: 'Room 3',
              ),
            ],
          ),
        );
        await tester.pump();

        expect(find.text('NO LESSONS'), findsOneWidget);
        expect(find.text('Room 3'), findsOneWidget);
      });

      testWidgets('shows NO DATA when nothing has ever synced', (
        tester,
      ) async {
        await tester.pumpWidget(_buildDashboard(prefs: prefs, shape: shape));
        await tester.pump();

        expect(find.text('NO DATA'), findsOneWidget);
      });

      testWidgets('shows a badge only when its count is non-zero', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildDashboard(
            prefs: prefs,
            shape: shape,
            inbox: [
              PocztaMessage(
                id: 1,
                title: 'Hi',
                senderName: 'Teacher',
                sendTime: DateTime(2025, 6, 15),
                isRead: false,
                isStarred: false,
              ),
            ],
          ),
        );
        await tester.pump();

        expect(find.text('1'), findsOneWidget);
      });

      testWidgets('caps badges at four with a +n overflow chip', (
        tester,
      ) async {
        await prefs.setStringList('new_grade_ids', ['1']);
        await tester.pumpWidget(
          _buildDashboard(
            prefs: prefs,
            shape: shape,
            inbox: [
              PocztaMessage(
                id: 1,
                title: 'Hi',
                senderName: 'Teacher',
                sendTime: DateTime(2025, 6, 15),
                isRead: false,
                isStarred: false,
              ),
            ],
            tests: [
              PortalTest(
                id: 1,
                subjectName: 'Math',
                date: _isoDate(DateTime.now().add(const Duration(days: 3))),
              ),
            ],
            reprimands: [
              PortalReprimand(
                id: 1,
                date: _isoDate(DateTime.now()),
                teacherName: 'Teacher',
                content: 'Good job',
                type: 2,
              ),
            ],
            bulletins: [
              PortalBulletin(
                id: 1,
                title: 'Trip',
                content: 'Content',
                date: _isoDate(DateTime.now()),
                author: 'Author',
                isRead: false,
              ),
            ],
          ),
        );
        await tester.pump();

        expect(find.textContaining('+'), findsOneWidget);
      });

      testWidgets('every badge tap target is at least 48dp', (tester) async {
        await tester.pumpWidget(
          _buildDashboard(
            prefs: prefs,
            shape: shape,
            inbox: [
              PocztaMessage(
                id: 1,
                title: 'Hi',
                senderName: 'Teacher',
                sendTime: DateTime(2025, 6, 15),
                isRead: false,
                isStarred: false,
              ),
            ],
          ),
        );
        await tester.pump();

        final size = tester.getSize(find.byType(InkWell).first);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      });
    });
  }
}
