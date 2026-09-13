import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

const double wearMinFontSizeSp = 10;
const double _stepGranularitySp = 0.5;

class WearFittedText extends StatelessWidget {
  const WearFittedText(
    this.data, {
    this.style,
    this.maxLines = 1,
    this.textAlign,
    this.minFontSize = wearMinFontSizeSp,
    this.group,
    super.key,
  });

  final String data;
  final TextStyle? style;
  final int maxLines;
  final TextAlign? textAlign;
  final double minFontSize;
  final AutoSizeGroup? group;

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      data,
      style: style,
      maxLines: maxLines,
      minFontSize: minFontSize,
      stepGranularity: _stepGranularitySp,
      wrapWords: false,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      group: group,
    );
  }
}
