import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/wear/widgets/wear_fitted_text.dart';
import 'package:bsharp/wear/widgets/wear_list_item.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
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
    final theme = Theme.of(context);

    return WearSwipeDismiss(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: WearScaffold(
          scrollController: _scrollController,
          child: Builder(
            builder: (context) => SingleChildScrollView(
              controller: _scrollController,
              padding: wearProsePadding(WearDisplayScope.of(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WearFittedText(
                    widget.bulletin.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: WearFittedText(
                          widget.bulletin.author,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
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
                  SelectableText(
                    widget.bulletin.content,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
