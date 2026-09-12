import 'package:bsharp/app/providers/more_providers.dart';
import 'package:bsharp/domain/annotation_utils.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/domain/portal_date_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/widgets/wear_tile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearNotesTile extends ConsumerWidget {
  const WearNotesTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remarks = ref.watch(remarksProvider);
    final praises = ref.watch(praisesProvider);
    final info = ref.watch(infoProvider);
    final unreadCount =
        ref.watch(unreadRemarksCountProvider) +
        ref.watch(unreadPraisesCountProvider) +
        ref.watch(unreadInfoCountProvider);
    final theme = Theme.of(context);

    final combined = [...remarks, ...praises, ...info]
      ..sort(
        (a, b) => parsePortalDate(b.date).compareTo(parsePortalDate(a.date)),
      );

    return Column(
      children: [
        WearTileHeader(
          icon: Icons.sticky_note_2_outlined,
          title: t.notes.title,
          trailing: unreadCount > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onTertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        ),
        if (combined.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 28,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.notes.noRemarks,
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
              padding: EdgeInsets.zero,
              itemCount: combined.take(3).length,
              itemBuilder: (context, index) {
                return _WearNoteItem(item: combined[index]);
              },
            ),
          ),
      ],
    );
  }
}

class _WearNoteItem extends StatelessWidget {
  const _WearNoteItem({required this.item});

  final PortalReprimand item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = annotationStyle(item.type, brightness: theme.brightness);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(style.icon, size: 14, color: style.color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.content,
                  style: theme.textTheme.labelSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.teacherName,
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
