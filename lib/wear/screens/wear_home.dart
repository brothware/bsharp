import 'dart:async';

import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/wear/screens/wear_attendance_tile.dart';
import 'package:bsharp/wear/screens/wear_bulletins_tile.dart';
import 'package:bsharp/wear/screens/wear_grades_tile.dart';
import 'package:bsharp/wear/screens/wear_homework_tile.dart';
import 'package:bsharp/wear/screens/wear_messages_tile.dart';
import 'package:bsharp/wear/screens/wear_notes_tile.dart';
import 'package:bsharp/wear/screens/wear_schedule_tile.dart';
import 'package:bsharp/wear/screens/wear_settings_tile.dart';
import 'package:bsharp/wear/screens/wear_tests_tile.dart';
import 'package:bsharp/wear/widgets/wear_crown_scroll.dart';
import 'package:bsharp/wear/widgets/wear_page_indicator.dart';
import 'package:bsharp/wear/widgets/wear_screen_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wear_home.g.dart';

@Riverpod(keepAlive: true)
class WearPageIndex extends _$WearPageIndex {
  @override
  int build() => 0;
  int get value => state;
  set value(int v) => state = v;
}

class WearHome extends ConsumerStatefulWidget {
  const WearHome({super.key});

  @override
  ConsumerState<WearHome> createState() => _WearHomeState();
}

class _WearHomeState extends ConsumerState<WearHome> {
  late final PageController _controller;
  double _topOverscroll = 0;

  static const _dismissThreshold = 60.0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    switch (notification) {
      case OverscrollNotification(:final overscroll, :final metrics)
          when overscroll < 0 && metrics is PageMetrics:
        _topOverscroll += overscroll.abs();
      case ScrollEndNotification():
        if (_topOverscroll >= _dismissThreshold) {
          unawaited(SystemNavigator.pop());
        }
        _topOverscroll = 0;
      default:
        break;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(childModeProvider);
    final notifier = ref.read(childModeProvider.notifier);

    ref.listen(childModeProvider.select((s) => s.mode), (_, _) {
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
        ref.read(wearPageIndexProvider.notifier).value = 0;
      }
    });

    final tiles = <Widget>[
      if (notifier.isFeatureVisible(ChildModeFeature.schedule))
        const WearScheduleTile(),
      if (notifier.isFeatureVisible(ChildModeFeature.grades))
        const WearGradesTile(),
      if (notifier.isFeatureVisible(ChildModeFeature.attendance))
        const WearAttendanceTile(),
      const WearHomeworkTile(),
      const WearTestsTile(),
      if (notifier.isFeatureVisible(ChildModeFeature.notes))
        const WearNotesTile(),
      if (notifier.isFeatureVisible(ChildModeFeature.messages))
        const WearMessagesTile(),
      const WearBulletinsTile(),
      const WearSettingsTile(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: WearScreenLayout(
        topFactor: 0.04,
        child: Stack(
          children: [
            WearCrownScroll(
              controller: _controller,
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: PageView(
                  scrollDirection: Axis.vertical,
                  controller: _controller,
                  onPageChanged: (i) =>
                      ref.read(wearPageIndexProvider.notifier).value = i,
                  children: tiles,
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: Consumer(
                  builder: (context, ref, _) {
                    final index = ref.watch(wearPageIndexProvider);
                    return WearPageIndicator(
                      count: tiles.length,
                      currentIndex: index,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
