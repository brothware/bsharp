import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:flutter/material.dart';

void pushWearSection(BuildContext context, WidgetBuilder builder) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => WearSwipeDismiss(
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: WearScaffold(child: builder(context)),
        ),
      ),
    ),
  );
}
