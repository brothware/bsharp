import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearScreenLayout extends ConsumerWidget {
  const WearScreenLayout({
    required this.child,
    this.topFactor = 0.12,
    super.key,
  });

  final Widget child;
  final double topFactor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shape = ref.watch(wearScreenShapeProvider).requireValue;

    if (shape == WearScreenShape.rectangular) {
      return SafeArea(child: child);
    }

    final size = MediaQuery.sizeOf(context);
    return Padding(
      padding: EdgeInsets.only(
        left: size.width * 0.10,
        right: size.width * 0.10,
        top: size.height * topFactor,
        bottom: size.height * 0.06,
      ),
      child: child,
    );
  }
}
