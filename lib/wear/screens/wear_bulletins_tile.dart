import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:bsharp/wear/screens/wear_bulletin_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_tile_header.dart';

class WearBulletinsTile extends ConsumerWidget {
  const WearBulletinsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shape = ref.watch(wearScreenShapeProvider).requireValue;
    final bulletins = ref.watch(bulletinsProvider);
    final unread = ref.watch(unreadBulletinsCountProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        WearTileHeader(
          icon: Icons.campaign_outlined,
          title: t.bulletins.title,
          trailing: unread > 0
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$unread',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        ),
        if (bulletins.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 28,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.bulletins.noBulletins,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(8, 0, 8, wearListBottomInset(shape)),
              itemCount: bulletins.take(4).length,
              itemBuilder: (context, index) {
                  final item = bulletins[index];
                  return InkWell(
                    onTap: () => _openDetail(context, item),
                    borderRadius: BorderRadius.circular(8),
                    child: _WearBulletinItem(item: item),
                  );
              },
            ),
          ),
      ],
    );
  }

  void _openDetail(BuildContext context, PortalBulletin bulletin) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WearBulletinDetailScreen(bulletin: bulletin),
      ),
    );
  }
}

class _WearBulletinItem extends StatelessWidget {
  const _WearBulletinItem({required this.item});

  final PortalBulletin item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: !item.isRead
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
      ),
      child: Row(
        children: [
          if (!item.isRead)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.author,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.date,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
