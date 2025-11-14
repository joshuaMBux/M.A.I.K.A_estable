import '../entities/reading_plan.dart';

abstract class ReadingPlanRepository {
  Future<int?> getDefaultPlanId();
  Future<ReadingPlan> getPlanDetail({required int planId, int? userId});
  Future<void> toggleDayCompletion({
    required int planId,
    required int day,
    int? userId,
    required bool completed,
  });
}
