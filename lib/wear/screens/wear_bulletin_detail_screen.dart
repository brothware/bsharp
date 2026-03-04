import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_crown_scroll.dart';
import 'package:bsharp/wear/widgets/wear_screen_layout.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearBulletinDetailScreen extends ConsumerStatefulWidget {
  const WearBulletinDetailScreen({required this.bulletin, super.key});

  final PortalBulletin bulletin;

  @override
  ConsumerState<WearBulletinDetailScreen> createState() =>
      _WearBulletinDetailScreenState();
}

class _WearBulletinDetailScreenState
    extends ConsumerState<WearBulletinDetailScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shape = ref.watch(wearScreenShapeProvider).requireValue;
    final theme = Theme.of(context);

    return WearSwipeDismiss(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: WearScreenLayout(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.bulletin.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.bulletin.author,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    widget.bulletin.date,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Divider(height: 8, color: theme.colorScheme.outlineVariant),
              Expanded(
                child: WearCrownScroll(
                  controller: _scrollController,
                  child: Scrollbar(
                    controller: _scrollController,
                    child: ListView(
                      controller: _scrollController,
                      padding: EdgeInsets.only(
                        bottom: wearListBottomInset(shape),
                      ),
                      children: [
                        SelectableText(
                          widget.bulletin.content,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
