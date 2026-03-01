import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:bsharp/wear/screens/wear_notes_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_forward_swipe.dart';
import 'package:bsharp/wear/widgets/wear_tile_header.dart';

class WearNotesTile extends ConsumerWidget {
  const WearNotesTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shape = ref.watch(wearScreenShapeProvider).requireValue;
    final notes = ref.watch(notesProvider);
    final praises = ref.watch(praisesProvider);
    final theme = Theme.of(context);

    final combined = [...notes, ...praises]
      ..sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));

    return WearForwardSwipe(
      onTriggered: () => _openDetail(context),
      child: Column(
        children: [
          WearTileHeader(
            icon: Icons.sticky_note_2_outlined,
            title: t.notes.title,
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
                      t.notes.noNotes,
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
                itemCount: combined.take(3).length,
                itemBuilder: (context, index) {
                  return _WearNoteItem(item: combined[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const WearNotesDetailScreen(),
      ),
    );
  }

  DateTime _parseDate(String date) {
    try {
      return DateTime.parse(date);
    } on FormatException catch (_) {
      final parts = date.split('.');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
      return DateTime(2000);
    }
  }
}

class _WearNoteItem extends StatelessWidget {
  const _WearNoteItem({required this.item});

  final PortalReprimand item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNote = item.type == 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isNote ? Icons.warning_amber : Icons.emoji_events,
            size: 14,
            color: isNote ? Colors.orange : Colors.green,
          ),
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
