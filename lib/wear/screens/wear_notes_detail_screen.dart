import 'package:bsharp/app/providers/more_providers.dart';
import 'package:bsharp/domain/annotation_utils.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/widgets/wear_fitted_text.dart';
import 'package:bsharp/wear/widgets/wear_list_item.dart';
import 'package:bsharp/wear/widgets/wear_period_selector.dart';
import 'package:bsharp/wear/widgets/wear_pinned_header.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:bsharp/wear/widgets/wear_side_navigation.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:bsharp/wear/widgets/wear_translate_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearNotesDetailScreen extends ConsumerStatefulWidget {
  const WearNotesDetailScreen({super.key});

  @override
  ConsumerState<WearNotesDetailScreen> createState() =>
      _WearNotesDetailScreenState();
}

enum _NotesTab { remarks, praises, info }

class _WearNotesDetailScreenState extends ConsumerState<WearNotesDetailScreen> {
  _NotesTab _activeTab = _NotesTab.remarks;
  final _translations = <int, String>{};
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _stepTab(int delta) {
    const tabs = _NotesTab.values;
    final next = (tabs.indexOf(_activeTab) + delta) % tabs.length;
    setState(() => _activeTab = tabs[next]);
  }

  @override
  Widget build(BuildContext context) {
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
        body: WearScaffold(
          scrollController: _scrollController,
          edgeContent: WearSideNavigation(
            onPrevious: () => _stepTab(-1),
            onNext: () => _stepTab(1),
          ),
          child: Column(
            children: [
              WearPinnedHeader(
                child: _WearNotesTabSelector(activeTab: _activeTab),
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
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                        itemCount: items.length,
                        itemBuilder: wearScaledItems(_scrollController, (
                          context,
                          index,
                        ) {
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
                        }),
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
  const _WearNotesTabSelector({required this.activeTab});

  final _NotesTab activeTab;

  String _labelFor(_NotesTab tab) => switch (tab) {
    _NotesTab.remarks => t.notes.remarksTab,
    _NotesTab.praises => t.notes.praisesTab,
    _NotesTab.info => t.notes.infoTab,
  };

  @override
  Widget build(BuildContext context) {
    return WearPeriodSelector(label: _labelFor(activeTab));
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = annotationStyle(item.type, brightness: theme.brightness);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(style.icon, size: 14, color: style.color),
              const SizedBox(width: 4),
              Expanded(
                child: WearFittedText(
                  item.teacherName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
