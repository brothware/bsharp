import 'package:freezed_annotation/freezed_annotation.dart';

part 'custom_event.freezed.dart';

enum RecurrenceType {
  occurrence,
  weekly
  ;

  static RecurrenceType fromIndex(int index) =>
      index == 1 ? weekly : occurrence;
}

@freezed
abstract class CustomEvent with _$CustomEvent {
  const factory CustomEvent({
    required int id,
    required int accountId,
    required String title,
    required String startTime,
    required String endTime,
    String? place,
    String? description,
    @Default(0) int colorIndex,
    @Default(RecurrenceType.occurrence) RecurrenceType recurrenceType,
    DateTime? recurrenceStartDate,
    DateTime? recurrenceEndDate,
    int? recurrenceWeekdays,
  }) = _CustomEvent;
}
