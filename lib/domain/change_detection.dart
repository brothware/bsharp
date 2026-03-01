enum ChangeCategory {
  grades,
  schedule,
  attendance,
  messages,
  homework,
  notes,
}

class ChangeItem {
  const ChangeItem({
    required this.category,
    required this.title,
    this.subtitle,
    this.entityId,
  });

  final ChangeCategory category;
  final String title;
  final String? subtitle;
  final int? entityId;
}

class ChangeSet {
  const ChangeSet({this.changes = const []});

  final List<ChangeItem> changes;

  bool get isEmpty => changes.isEmpty;
  bool get isNotEmpty => changes.isNotEmpty;
  int get totalCount => changes.length;

  List<ChangeItem> byCategory(ChangeCategory category) =>
      changes.where((c) => c.category == category).toList();

  int countByCategory(ChangeCategory category) =>
      changes.where((c) => c.category == category).length;

  ChangeSet merge(ChangeSet other) =>
      ChangeSet(changes: [...changes, ...other.changes]);

  Map<ChangeCategory, List<ChangeItem>> get grouped {
    final result = <ChangeCategory, List<ChangeItem>>{};
    for (final change in changes) {
      result.putIfAbsent(change.category, () => []).add(change);
    }
    return result;
  }

  String summary({
    required String Function(int count) gradesLabel,
    required String Function(int count) messagesLabel,
    required String Function(int count) scheduleLabel,
    required String Function(int count) attendanceLabel,
    required String Function(int count) homeworkLabel,
    required String Function(int count) notesLabel,
    required String noChanges,
    required String Function(String summary) newChanges,
  }) {
    final parts = <String>[];
    final g = grouped;
    if (g.containsKey(ChangeCategory.grades)) {
      parts.add(gradesLabel(g[ChangeCategory.grades]!.length));
    }
    if (g.containsKey(ChangeCategory.messages)) {
      parts.add(messagesLabel(g[ChangeCategory.messages]!.length));
    }
    if (g.containsKey(ChangeCategory.schedule)) {
      parts.add(scheduleLabel(g[ChangeCategory.schedule]!.length));
    }
    if (g.containsKey(ChangeCategory.attendance)) {
      parts.add(attendanceLabel(g[ChangeCategory.attendance]!.length));
    }
    if (g.containsKey(ChangeCategory.homework)) {
      parts.add(homeworkLabel(g[ChangeCategory.homework]!.length));
    }
    if (g.containsKey(ChangeCategory.notes)) {
      parts.add(notesLabel(g[ChangeCategory.notes]!.length));
    }
    if (parts.isEmpty) return noChanges;
    return newChanges(parts.join(', '));
  }
}

class BackoffStrategy {
  const BackoffStrategy({
    this.baseInterval = const Duration(minutes: 30),
    this.maxInterval = const Duration(hours: 4),
    this.multiplier = 2.0,
  });

  final Duration baseInterval;
  final Duration maxInterval;
  final double multiplier;

  Duration intervalAfterFailures(int failureCount) {
    if (failureCount <= 0) return baseInterval;

    var interval = baseInterval;
    for (var i = 0; i < failureCount; i++) {
      interval = Duration(
        milliseconds: (interval.inMilliseconds * multiplier).round(),
      );
      if (interval >= maxInterval) return maxInterval;
    }
    return interval;
  }
}
