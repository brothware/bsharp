enum SyncAction {
  insert,
  update,
  delete
  ;

  static SyncAction fromString(String value) => switch (value) {
    'I' => insert,
    'U' => update,
    'D' => delete,
    _ => throw ArgumentError('Unknown sync action: $value'),
  };

  String toJsonValue() => switch (this) {
    insert => 'I',
    update => 'U',
    delete => 'D',
  };
}

enum Sex {
  female,
  male
  ;

  static Sex fromString(String value) => switch (value) {
    'K' => female,
    'M' => male,
    _ => throw ArgumentError('Unknown sex: $value'),
  };

  String toJsonValue() => switch (this) {
    female => 'K',
    male => 'M',
  };
}

enum AttendanceCountAs {
  present,
  absent,
  late,
  other
  ;

  static AttendanceCountAs fromString(String value) => switch (value) {
    'P' => present,
    'A' => absent,
    'L' => late,
    _ => other,
  };
}

enum AttendanceExcuseStatus {
  excused,
  unexcused,
  auto,
  unset
  ;

  static AttendanceExcuseStatus fromString(String? value) => switch (value) {
    'E' => excused,
    'N' => unexcused,
    'A' => auto,
    _ => unset,
  };
}

enum ReprimandKind {
  note,
  praise
  ;

  static ReprimandKind fromInt(int value) => switch (value) {
    0 => note,
    1 => praise,
    _ => throw ArgumentError('Unknown reprimand kind: $value'),
  };

  int toJsonValue() => switch (this) {
    note => 0,
    praise => 1,
  };
}

enum TermType {
  year,
  semester
  ;

  static TermType fromString(String value) => switch (value) {
    'Y' => year,
    _ => semester,
  };
}
