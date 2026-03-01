import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/widgets/translate_button.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final praises = ref.watch(praisesProvider);

    return DefaultTabController(
      length: 2,
      child: RefreshIndicator(
        onRefresh: () => ref.read(syncStatusProvider.notifier).sync(),
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.notes.notesTab),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _CountBadge(count: notes.length),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.notes.praisesTab),
                      if (praises.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _CountBadge(count: praises.length),
                      ],
                    ],
                  ),
                ),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ReprimandList(
                    items: notes,
                    emptyIcon: Icons.note_outlined,
                    emptyText: t.notes.noNotes,
                  ),
                  _ReprimandList(
                    items: praises,
                    emptyIcon: Icons.emoji_events_outlined,
                    emptyText: t.notes.noPraises,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ReprimandList extends StatelessWidget {
  const _ReprimandList({
    required this.items,
    required this.emptyIcon,
    required this.emptyText,
  });

  final List<PortalReprimand> items;
  final IconData emptyIcon;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(icon: emptyIcon, text: emptyText);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _ReprimandTile(item: item);
      },
    );
  }
}

class _ReprimandTile extends StatelessWidget {
  const _ReprimandTile({required this.item});

  final PortalReprimand item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNote = item.type == 0;

    return Card(
      child: ListTile(
        leading: Icon(
          isNote ? Icons.warning_amber_outlined : Icons.emoji_events_outlined,
          color: isNote ? Colors.orange : Colors.green,
        ),
        title: Text(
          item.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${item.teacherName} • ${item.date}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: () => _showDetail(context, item),
      ),
    );
  }

  void _showDetail(BuildContext context, PortalReprimand item) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _ReprimandDetailSheet(item: item),
    );
  }
}

class _ReprimandDetailSheet extends ConsumerStatefulWidget {
  const _ReprimandDetailSheet({required this.item});

  final PortalReprimand item;

  @override
  ConsumerState<_ReprimandDetailSheet> createState() =>
      _ReprimandDetailSheetState();
}

class _ReprimandDetailSheetState extends ConsumerState<_ReprimandDetailSheet> {
  String? _translatedContent;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final translationAvailable = ref.watch(isTranslationAvailableProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.type == 0
                    ? Icons.warning_amber_outlined
                    : Icons.emoji_events_outlined,
                color: item.type == 0 ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                item.type == 0 ? t.notes.note : t.notes.praise,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(t.notes.teacherLabel(name: item.teacherName)),
          Text(t.notes.dateLabel(date: item.date)),
          const SizedBox(height: 16),
          Text(_translatedContent ?? item.content),
          if (translationAvailable)
            TranslateButton(
              sourceText: item.content,
              onTranslated: (translated) =>
                  setState(() => _translatedContent = translated),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(text, style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}
