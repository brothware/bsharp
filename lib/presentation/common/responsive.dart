import 'package:flutter/widgets.dart';

enum ScreenSize { phone, tablet, desktop }

abstract final class Breakpoints {
  static const double tablet = 600;
  static const double desktop = 1200;
}

ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= Breakpoints.desktop) return ScreenSize.desktop;
  if (width >= Breakpoints.tablet) return ScreenSize.tablet;
  return ScreenSize.phone;
}

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    required this.phone,
    this.tablet,
    this.desktop,
    super.key,
  });

  final Widget phone;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    final size = screenSizeOf(context);
    return switch (size) {
      ScreenSize.desktop => desktop ?? tablet ?? phone,
      ScreenSize.tablet => tablet ?? phone,
      ScreenSize.phone => phone,
    };
  }
}

class ResponsivePadding extends StatelessWidget {
  const ResponsivePadding({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = screenSizeOf(context);
    final horizontal = switch (size) {
      ScreenSize.phone => 16.0,
      ScreenSize.tablet => 24.0,
      ScreenSize.desktop => 32.0,
    };
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      child: child,
    );
  }
}

class ResponsiveConstrainedBox extends StatelessWidget {
  const ResponsiveConstrainedBox({
    required this.child,
    this.maxWidth = 800,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
