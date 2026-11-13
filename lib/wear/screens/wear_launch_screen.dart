import 'package:flutter/material.dart';

/// What the watch shows between the native splash and the first real screen:
/// the same icon at the same size on the same black, so the branded launch
/// reads as one screen instead of handing over to a spinner.
class WearLaunchScreen extends StatelessWidget {
  const WearLaunchScreen({super.key});

  static const double iconSizeDp = 48;

  /// How much of the logo file the artwork fills; the rest is a transparent
  /// border that the image box has to allow for.
  static const double artworkFraction = 928 / 1024;

  @override
  Widget build(BuildContext context) {
    const imageSizeDp = iconSizeDp / artworkFraction;

    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Image(
          image: AssetImage('assets/logo.png'),
          width: imageSizeDp,
          height: imageSizeDp,
        ),
      ),
    );
  }
}
