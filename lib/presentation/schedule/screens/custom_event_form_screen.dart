import 'package:bsharp/domain/custom_event_utils.dart';
import 'package:bsharp/domain/entities/custom_event.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/schedule/providers/custom_event_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomEventFormScreen extends ConsumerStatefulWidget {
  const CustomEventFormScreen({super.key, this.event});

  final CustomEvent? event;

  @override
  ConsumerState<CustomEventFormScreen> createState() =>
      _CustomEventFormScreenState();
}

class _CustomEventFormScreenState extends ConsumerState<CustomEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _placeController;
  late final TextEditingController _descriptionController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _colorIndex;
  late RecurrenceType _recurrenceType;
  DateTime? _recurrenceStartDate;
  DateTime? _recurrenceEndDate;
  int _weekdayBitmask = 0;
  List<DateTime> _occurrenceDates = [];
  bool _saving = false;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleController = TextEditingController(text: e?.title ?? '');
    _placeController = TextEditingController(text: e?.place ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _startTime = e != null
        ? _parseTime(e.startTime)
        : const TimeOfDay(hour: 15, minute: 0);
    _endTime = e != null
        ? _parseTime(e.endTime)
        : const TimeOfDay(hour: 16, minute: 0);
    _colorIndex = e?.colorIndex ?? 0;
    _recurrenceType = e?.recurrenceType ?? RecurrenceType.occurrence;
    _recurrenceStartDate = e?.recurrenceStartDate;
    _recurrenceEndDate = e?.recurrenceEndDate;
    _weekdayBitmask = e?.recurrenceWeekdays ?? 0;

    if (_isEditing && _recurrenceType == RecurrenceType.occurrence) {
      _loadExistingOccurrences();
    }
  }

  Future<void> _loadExistingOccurrences() async {
    final dao = ref.read(customEventDaoProvider);
    if (dao == null) return;
    final now = DateTime.now();
    final occs = await dao.getOccurrencesInRange(
      widget.event!.accountId,
      now.subtract(const Duration(days: 365)),
      now.add(const Duration(days: 365)),
    );
    setState(() {
      _occurrenceDates =
          occs
              .where((o) => o.customEventId == widget.event!.id)
              .map((o) => o.date)
              .toList()
            ..sort();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay tod) =>
      '${tod.hour.toString().padLeft(2, '0')}:'
      '${tod.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? t.schedule.customEvent.edit
              : t.schedule.customEvent.create,
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(t.common.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: t.schedule.customEvent.eventTitle,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? t.schedule.customEvent.titleRequired
                  : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _placeController,
              decoration: InputDecoration(
                labelText: t.schedule.customEvent.place,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: t.schedule.customEvent.description,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),
            Text(
              t.schedule.customEvent.color,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            _ColorPicker(
              selectedIndex: _colorIndex,
              onChanged: (i) => setState(() => _colorIndex = i),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _TimeTile(
                    label: t.schedule.customEvent.startTime,
                    time: _startTime,
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeTile(
                    label: t.schedule.customEvent.endTime,
                    time: _endTime,
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              t.schedule.customEvent.recurrence,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SegmentedButton<RecurrenceType>(
              segments: [
                ButtonSegment(
                  value: RecurrenceType.occurrence,
                  label: Text(t.schedule.customEvent.specificDates),
                ),
                ButtonSegment(
                  value: RecurrenceType.weekly,
                  label: Text(t.schedule.customEvent.weekly),
                ),
              ],
              selected: {_recurrenceType},
              onSelectionChanged: (s) =>
                  setState(() => _recurrenceType = s.first),
            ),
            const SizedBox(height: 12),
            if (_recurrenceType == RecurrenceType.weekly) ...[
              _DateRangePicker(
                startDate: _recurrenceStartDate,
                endDate: _recurrenceEndDate,
                onStartChanged: (d) => setState(() => _recurrenceStartDate = d),
                onEndChanged: (d) => setState(() => _recurrenceEndDate = d),
              ),
              const SizedBox(height: 12),
              Text(
                t.schedule.customEvent.weekdays,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (i) {
                  final weekday = i + 1;
                  final selected = weekdayBitmaskHas(_weekdayBitmask, weekday);
                  return FilterChip(
                    label: Text(dayLabel(weekday)),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      _weekdayBitmask = weekdayBitmaskSet(
                        _weekdayBitmask,
                        weekday,
                        enabled: v,
                      );
                    }),
                  );
                }),
              ),
            ] else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonal(
                  onPressed: _addOccurrenceDate,
                  child: Text(t.schedule.customEvent.addDate),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final date in _occurrenceDates)
                    Chip(
                      label: Text(formatDateFull(date)),
                      onDeleted: () =>
                          setState(() => _occurrenceDates.remove(date)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _addOccurrenceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final normalized = DateTime(picked.year, picked.month, picked.day);
      if (!_occurrenceDates.any((d) => isSameDay(d, normalized))) {
        setState(() {
          _occurrenceDates
            ..add(normalized)
            ..sort();
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.schedule.customEvent.endBeforeStart)),
      );
      return;
    }

    if (_recurrenceType == RecurrenceType.occurrence &&
        _occurrenceDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.schedule.customEvent.noDatesSelected)),
      );
      return;
    }

    setState(() => _saving = true);

    final accountId = widget.event?.accountId ?? 1;

    final event = CustomEvent(
      id: widget.event?.id ?? 0,
      accountId: accountId,
      title: _titleController.text.trim(),
      place: _placeController.text.trim().isEmpty
          ? null
          : _placeController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      startTime: _formatTimeOfDay(_startTime),
      endTime: _formatTimeOfDay(_endTime),
      colorIndex: _colorIndex,
      recurrenceType: _recurrenceType,
      recurrenceStartDate: _recurrenceType == RecurrenceType.weekly
          ? _recurrenceStartDate
          : null,
      recurrenceEndDate: _recurrenceType == RecurrenceType.weekly
          ? _recurrenceEndDate
          : null,
      recurrenceWeekdays: _recurrenceType == RecurrenceType.weekly
          ? _weekdayBitmask
          : null,
    );

    await saveCustomEvent(ref, event, _occurrenceDates);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.schedule.customEvent.saved)));
      Navigator.of(context).pop();
    }
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(12, (i) {
        final color = subjectColor(i);
        final isSelected = i == selectedIndex;
        return GestureDetector(
          onTap: () => onChanged(i),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 3,
                    )
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(time.format(context), style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _DateRangePicker extends StatelessWidget {
  const _DateRangePicker({
    required this.startDate,
    required this.endDate,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<DateTime> onEndChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: startDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) onStartChanged(picked);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.schedule.customEvent.from,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    startDate != null ? formatDateFull(startDate!) : '—',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: endDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) onEndChanged(picked);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.schedule.customEvent.to,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    endDate != null ? formatDateFull(endDate!) : '—',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
