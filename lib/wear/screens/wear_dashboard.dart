import 'package:bsharp/wear/widgets/wear_lesson_hero.dart';
import 'package:bsharp/wear/widgets/wear_news_badges.dart';
import 'package:flutter/material.dart';

class WearDashboard extends StatelessWidget {
  const WearDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WearLessonHero(),
        SizedBox(height: 8),
        WearNewsBadges(),
      ],
    );
  }
}
