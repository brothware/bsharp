import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/presentation/common/responsive.dart';

void main() {
  group('Breakpoints', () {
    test('constants have correct values', () {
      expect(Breakpoints.tablet, 600);
      expect(Breakpoints.desktop, 1200);
    });
  });

  group('ResponsiveBuilder', () {
    testWidgets('shows phone widget on small screen', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveBuilder(
            phone: Text('phone'),
            tablet: Text('tablet'),
            desktop: Text('desktop'),
          ),
        ),
      );

      expect(find.text('phone'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('shows tablet widget on medium screen', (tester) async {
      tester.view.physicalSize = const Size(800, 1024);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveBuilder(
            phone: Text('phone'),
            tablet: Text('tablet'),
            desktop: Text('desktop'),
          ),
        ),
      );

      expect(find.text('tablet'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('shows desktop widget on large screen', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveBuilder(
            phone: Text('phone'),
            tablet: Text('tablet'),
            desktop: Text('desktop'),
          ),
        ),
      );

      expect(find.text('desktop'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('falls back to phone when tablet missing', (tester) async {
      tester.view.physicalSize = const Size(800, 1024);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(home: ResponsiveBuilder(phone: Text('phone'))),
      );

      expect(find.text('phone'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('falls back to tablet when desktop missing', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveBuilder(phone: Text('phone'), tablet: Text('tablet')),
        ),
      );

      expect(find.text('tablet'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('screenSizeOf', () {
    testWidgets('returns phone for width < 600', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;

      late ScreenSize result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = screenSizeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, ScreenSize.phone);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('returns tablet for 600 <= width < 1200', (tester) async {
      tester.view.physicalSize = const Size(800, 1024);
      tester.view.devicePixelRatio = 1.0;

      late ScreenSize result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = screenSizeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, ScreenSize.tablet);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('returns desktop for width >= 1200', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;

      late ScreenSize result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = screenSizeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, ScreenSize.desktop);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
