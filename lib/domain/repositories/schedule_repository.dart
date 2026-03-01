import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/domain/entities/event.dart';
import 'package:bsharp/domain/entities/portal.dart';

abstract interface class ScheduleRepository {
  Stream<List<Event>> watchEventsForDate(DateTime date);

  Stream<List<Event>> watchEventsForRange(DateTime start, DateTime end);

  Future<Result<List<PortalTimetableEvent>>> fetchTimetable({
    required int pupilId,
    required DateTime dateFrom,
    required DateTime dateTo,
  });
}
