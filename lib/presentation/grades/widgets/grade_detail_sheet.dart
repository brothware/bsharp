import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/domain/grade_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/widgets/translate_button.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GradeDetailSheet extends ConsumerStatefulWidget {
  const GradeDetailSheet({
    required this.resolvedMark,
    required this.subjectName,
    super.key,
  });

  final ResolvedMark resolvedMark;
  final String subjectName;

  @override
  ConsumerState<GradeDetailSheet> createState() => _GradeDetailSheetState();
}

class _GradeDetailSheetState extends ConsumerState<GradeDetailSheet> {
  String? _translatedCategory;
  String? _translatedComment;
  String? _translatedDescription;

  @override
  Widget build(BuildContext context) {
    final mark = widget.resolvedMark.mark;
    final theme = Theme.of(context);
    final color = gradeColor(widget.resolvedMark.effectiveValue);
    final scales = ref.watch(markScalesProvider);
    final kinds = ref.watch(markKindsProvider);
    final groups = ref.watch(markGroupsProvider);
    final teachers = ref.watch(teachersProvider);
    final topPadding = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    final translationAvailable = ref.watch(isTranslationAvailableProvider);

    final scale = mark.markScalesId != null
        ? scales.where((s) => s.id == mark.markScalesId).firstOrNull
        : null;

    final group = groups.where((g) => g.id == mark.markGroupsId).firstOrNull;
    final kind = group?.markKindsId != null
        ? kinds.where((k) => k.id == group!.markKindsId).firstOrNull
        : null;

    final teacher = teachers
        .where((t) => t.id == mark.teacherUsersId)
        .firstOrNull;

    final displayValue = widget.resolvedMark.displayValue;

    return Container(
      height: screenHeight - topPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    widget.subjectName,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 72,
                      minHeight: 72,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      displayValue,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    widget.subjectName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (scale != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Center(
                      child: Text(
                        translateGradeName(scale.name),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: t.grades.date,
                  value: _formatDate(mark.getDate),
                ),
                _DetailRow(
                  icon: Icons.fitness_center,
                  label: t.grades.weight,
                  value: mark.weight.toString(),
                ),
                if (kind != null)
                  _DetailRow(
                    icon: Icons.category,
                    label: t.grades.category,
                    value:
                        _translatedCategory ??
                        translateGradeCategory(kind.name),
                  ),
                if (group?.description != null &&
                    group!.description!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.description,
                    label: t.grades.description,
                    value: _translatedDescription ?? group.description!,
                  ),
                if (teacher != null)
                  _DetailRow(
                    icon: Icons.person,
                    label: t.grades.teacher,
                    value: '${teacher.name} ${teacher.surname}',
                  ),
                if (mark.comments != null && mark.comments!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.comment,
                    label: t.grades.comment,
                    value: _translatedComment ?? mark.comments!,
                  ),
                if (translationAvailable)
                  _buildTranslateButton(
                    kind?.name,
                    group?.description,
                    mark.comments,
                  ),
                if (widget.resolvedMark.effectiveValue != null)
                  _DetailRow(
                    icon: Icons.tag,
                    label: t.grades.numericValue,
                    value: widget.resolvedMark.effectiveValue!.toStringAsFixed(
                      2,
                    ),
                  ),
                if (widget.resolvedMark.isPointBased)
                  _DetailRow(
                    icon: Icons.score,
                    label: t.grades.points,
                    value:
                        '${mark.markValue?.toInt() ?? "?"} / ${widget.resolvedMark.markMax!.toInt()}',
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslateButton(
    String? category,
    String? description,
    String? comment,
  ) {
    final parts = <String>[
      if (category != null) category,
      if (description != null && description.isNotEmpty) description,
      if (comment != null && comment.isNotEmpty) comment,
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    const separator = '\n---\n';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TranslateButton(
        sourceText: parts.join(separator),
        onTranslated: (translated) {
          setState(() {
            if (translated != null) {
              final segments = translated.split(separator);
              var i = 0;
              if (category != null && i < segments.length) {
                _translatedCategory = segments[i++];
              }
              if (description != null &&
                  description.isNotEmpty &&
                  i < segments.length) {
                _translatedDescription = segments[i++];
              }
              if (comment != null &&
                  comment.isNotEmpty &&
                  i < segments.length) {
                _translatedComment = segments[i];
              }
            } else {
              _translatedCategory = null;
              _translatedDescription = null;
              _translatedComment = null;
            }
          });
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
