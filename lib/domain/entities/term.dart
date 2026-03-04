import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'term.freezed.dart';

@freezed
abstract class Term with _$Term {
  const factory Term({
    required int id,
    required String name,
    required TermType type,
    required DateTime startDate,
    required DateTime endDate,
    int? parentId,
  }) = _Term;
}
