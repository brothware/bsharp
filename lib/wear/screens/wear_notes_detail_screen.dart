import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_crown_scroll.dart';
import 'package:bsharp/wear/widgets/wear_screen_layout.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:bsharp/wear/widgets/wear_translate_button.dart';

class WearNotesDetailScreen extends ConsumerStatefulWidget {
  const WearNotesDetailScreen({super.key});

  @override
  ConsumerState<WearNotesDetailScreen> createState() =>
      _WearNotesDetailScreenState();
}

enum _NotesTab { remarks, praises, info }

class _WearNotesDetailScreenState
    extends ConsumerState<WearNotesDetailScreen> {
  var _activeTab = _NotesTab.remarks;
  final _translations = <int, String>{};
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shape = ref.watch(wearScreenShapeProvider).requireValue;
    final remarks = ref.watch(remarksProvider);
    final praises = ref.watch(praisesProvider);
    final info = ref.watch(infoProvider);
    final theme = Theme.of(context);

    final (items, emptyText) = switch (_activeTab) {
      _NotesTab.remarks => (remarks, t.notes.noRemarks),
      _NotesTab.praises => (praises, t.notes.noPraises),
      _NotesTab.info => (info, t.notes.noInfo),
    };

    return WearSwipeDismiss(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: WearScreenLayout(
          child: Column(
            children: [
              _WearNotesTabSelector(
                activeTab: _activeTab,
                onChanged: (tab) {
                  setState(() => _activeTab = tab);
                },
              ),
              const SizedBox(height: 4),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          emptyText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : WearCrownScroll(
                        controller: _scrollController,
                        child: Scrollbar(
                          controller: _scrollController,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(4, 0, 4, wearListBottomInset(shape)),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _WearNoteDetailItem(
                                item: item,
                                translatedContent: _translations[item.id],
                                onTranslated: (translated) {
                                  setState(() {
                                    if (translated != null) {
                                      _translations[item.id] = translated;
                                    } else {
                                      _translations.remove(item.id);
                                    }
                                  });
                                },
                              );
                            },
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

class _WearNotesTabSelector extends StatelessWidget {
  const _WearNotesTabSelector({
    required this.activeTab,
    required this.onChanged,
  });

  final _NotesTab activeTab;
  final ValueChanged<_NotesTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TabButton(
          label: t.notes.remarksTab,
          isSelected: activeTab == _NotesTab.remarks,
          onTap: () => onChanged(_NotesTab.remarks),
          theme: theme,
        ),
        const SizedBox(width: 4),
        _TabButton(
          label: t.notes.praisesTab,
          isSelected: activeTab == _NotesTab.praises,
          onTap: () => onChanged(_NotesTab.praises),
          theme: theme,
        ),
        const SizedBox(width: 4),
        _TabButton(
          label: t.notes.infoTab,
          isSelected: activeTab == _NotesTab.info,
          onTap: () => onChanged(_NotesTab.info),
          theme: theme,
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? theme.colorScheme.primary : null,
          border: isSelected
              ? null
              : Border.all(color: theme.colorScheme.outline),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }
}

class _WearNoteDetailItem extends StatelessWidget {
  const _WearNoteDetailItem({
    required this.item,
    required this.onTranslated,
    this.translatedContent,
  });

  final PortalReprimand item;
  final String? translatedContent;
  final ValueChanged<String?> onTranslated;

  static (IconData, Color) _iconForType(int type) => switch (type) {
        1 => (Icons.emoji_events, Colors.green),
        2 => (Icons.warning_amber, Colors.orange),
        _ => (Icons.info_outline, Colors.blue),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = _iconForType(item.type);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.teacherName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                item.date,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            translatedContent ?? item.content,
            style: theme.textTheme.labelSmall,
          ),
          WearTranslateButton(
            sourceText: item.content,
            onTranslated: onTranslated,
          ),
        ],
      ),
    );
  }
}
