import 'package:bsharp/domain/entities/mark.dart';
import 'package:bsharp/domain/grade_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/wear/screens/wear_grades_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_forward_swipe.dart';
import 'package:bsharp/wear/widgets/wear_tile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearGradesTile extends ConsumerWidget {
  const WearGradesTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shape = ref.watch(wearScreenShapeProvider).requireValue;
    final subjectGrades = ref.watch(subjectGradesProvider);
    final newIds = ref.watch(newGradeIdsProvider);
    final markGroups = ref.watch(markGroupsProvider);
    final markKinds = ref.watch(markKindsProvider);
    final theme = Theme.of(context);

    final allResolved = subjectGrades.expand((sg) => sg.resolvedMarks).toList()
      ..sort((a, b) => b.mark.getDate.compareTo(a.mark.getDate));
    final recent = allResolved.take(3).toList();

    final markIdToSubject = <int, String>{};
    for (final sg in subjectGrades) {
      for (final rm in sg.resolvedMarks) {
        markIdToSubject[rm.mark.id] = sg.subjectName;
      }
    }

    final groupById = {for (final g in markGroups) g.id: g};
    final kindById = {for (final k in markKinds) k.id: k};

    return WearForwardSwipe(
      onTriggered: () => _openDetail(context),
      child: Column(
        children: [
          WearTileHeader(
            icon: Icons.grade,
            title: t.nav.grades,
            trailing: allResolved.isNotEmpty
                ? Text(
                    '${allResolved.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : null,
          ),
          if (recent.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.grade_outlined,
                      size: 28,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.grades.noGrades,
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
                padding: EdgeInsets.fromLTRB(
                  8,
                  0,
                  8,
                  wearListBottomInset(shape),
                ),
                itemCount: recent.length,
                itemBuilder: (context, index) {
                  final rm = recent[index];
                  final isNew = newIds.contains(rm.mark.id);
                  final color = gradeColor(rm.effectiveValue);
                  final subjectName = markIdToSubject[rm.mark.id];
                  final category = _resolveCategory(
                    rm.mark.markGroupsId,
                    groupById,
                    kindById,
                  );

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isNew
                          ? theme.colorScheme.tertiaryContainer.withValues(
                              alpha: 0.3,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 28,
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            rm.displayValue,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (subjectName != null)
                                Text(
                                  subjectName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (category != null)
                                Text(
                                  category,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                _formatDateShort(rm.mark.getDate),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              t.grades.newBadge,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onTertiary,
                                fontSize: 8, // Intentionally small badge
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WearGradesDetailScreen()),
    );
  }

  String? _resolveCategory(
    int markGroupsId,
    Map<int, MarkGroup> groupById,
    Map<int, MarkKind> kindById,
  ) {
    final group = groupById[markGroupsId];
    if (group == null) return null;
    if (group.markKindsId == null) return null;
    final kind = kindById[group.markKindsId];
    if (kind == null) return null;
    return translateGradeCategory(kind.name);
  }
}

String _formatDateShort(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}';
}
