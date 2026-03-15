import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/domain/entities/resolved_grade.dart';
import 'package:bsharp/domain/grade_utils.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/widgets/translate_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GradeDetailSheet extends ConsumerStatefulWidget {
  const GradeDetailSheet({
    required this.grade,
    required this.subjectName,
    this.scrollController,
    super.key,
  });

  final ResolvedGrade grade;
  final String subjectName;
  final ScrollController? scrollController;

  @override
  ConsumerState<GradeDetailSheet> createState() => _GradeDetailSheetState();
}

class _GradeDetailSheetState extends ConsumerState<GradeDetailSheet> {
  String? _translatedCategory;
  String? _translatedComment;

  @override
  Widget build(BuildContext context) {
    final grade = widget.grade;
    final theme = Theme.of(context);
    final color = gradeColor(grade.effectiveValue);
    final translationAvailable = ref.watch(isTranslationAvailableProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.subjectName,
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
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
                grade.displayValue,
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
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: Text(
                translateGradeName(grade.displayValue),
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
            value: _formatDate(grade.date),
          ),
          _DetailRow(
            icon: Icons.fitness_center,
            label: t.grades.weight,
            value: grade.weight.toString(),
          ),
          _DetailRow(
            icon: Icons.category,
            label: t.grades.category,
            value:
                _translatedCategory ??
                translateGradeCategory(grade.categoryName),
          ),
          if (grade.teacherName != null)
            _DetailRow(
              icon: Icons.person,
              label: t.grades.teacher,
              value: grade.teacherName!,
            ),
          if (grade.comment != null && grade.comment!.isNotEmpty)
            _DetailRow(
              icon: Icons.comment,
              label: t.grades.comment,
              value: _translatedComment ?? grade.comment!,
            ),
          if (translationAvailable)
            _buildTranslateButton(
              grade.categoryName,
              grade.comment,
            ),
          if (grade.effectiveValue != null)
            _DetailRow(
              icon: Icons.tag,
              label: t.grades.numericValue,
              value: grade.effectiveValue!.toStringAsFixed(2),
            ),
          if (grade.markMax != null)
            _DetailRow(
              icon: Icons.score,
              label: t.grades.points,
              value:
                  '${grade.effectiveValue?.toInt() ?? "?"} / ${grade.markMax!.toInt()}',
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTranslateButton(
    String category,
    String? comment,
  ) {
    final hasComment = comment != null && comment.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: MultiTranslateButton(
        fields: [
          TranslationField(category),
          if (hasComment) TranslationField(comment),
        ],
        onTranslated: (translations) {
          setState(() {
            if (translations != null) {
              var i = 0;
              _translatedCategory = translations[i++];
              if (hasComment) _translatedComment = translations[i];
            } else {
              _translatedCategory = null;
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
