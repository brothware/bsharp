class ChildModeConfig {
  const ChildModeConfig({
    this.gradesVisible = true,
    this.scheduleVisible = true,
    this.attendanceVisible = true,
    this.messagesVisible = false,
    this.settingsVisible = false,
    this.notesVisible = true,
  });

  factory ChildModeConfig.fromJson(Map<String, dynamic> json) {
    return ChildModeConfig(
      gradesVisible: json['gradesVisible'] as bool? ?? true,
      scheduleVisible: json['scheduleVisible'] as bool? ?? true,
      attendanceVisible: json['attendanceVisible'] as bool? ?? true,
      messagesVisible: json['messagesVisible'] as bool? ?? false,
      settingsVisible: json['settingsVisible'] as bool? ?? false,
      notesVisible: json['notesVisible'] as bool? ?? true,
    );
  }

  final bool gradesVisible;
  final bool scheduleVisible;
  final bool attendanceVisible;
  final bool messagesVisible;
  final bool settingsVisible;
  final bool notesVisible;

  ChildModeConfig copyWith({
    bool? gradesVisible,
    bool? scheduleVisible,
    bool? attendanceVisible,
    bool? messagesVisible,
    bool? settingsVisible,
    bool? notesVisible,
  }) {
    return ChildModeConfig(
      gradesVisible: gradesVisible ?? this.gradesVisible,
      scheduleVisible: scheduleVisible ?? this.scheduleVisible,
      attendanceVisible: attendanceVisible ?? this.attendanceVisible,
      messagesVisible: messagesVisible ?? this.messagesVisible,
      settingsVisible: settingsVisible ?? this.settingsVisible,
      notesVisible: notesVisible ?? this.notesVisible,
    );
  }

  bool isFeatureVisible(ChildModeFeature feature) {
    return switch (feature) {
      ChildModeFeature.grades => gradesVisible,
      ChildModeFeature.schedule => scheduleVisible,
      ChildModeFeature.attendance => attendanceVisible,
      ChildModeFeature.messages => messagesVisible,
      ChildModeFeature.settings => settingsVisible,
      ChildModeFeature.notes => notesVisible,
    };
  }

  Map<String, dynamic> toJson() => {
    'gradesVisible': gradesVisible,
    'scheduleVisible': scheduleVisible,
    'attendanceVisible': attendanceVisible,
    'messagesVisible': messagesVisible,
    'settingsVisible': settingsVisible,
    'notesVisible': notesVisible,
  };
}

enum ChildModeFeature {
  grades,
  schedule,
  attendance,
  messages,
  settings,
  notes,
}
