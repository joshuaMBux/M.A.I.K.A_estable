import '../../repositories/reading_plan_repository.dart';

class ToggleReadingPlanDayUseCase {
  final ReadingPlanRepository repository;

  ToggleReadingPlanDayUseCase(this.repository);

  Future<void> call({
    required int planId,
    required int day,
    int? userId,
    required bool completed,
  }) {
    return repository.toggleDayCompletion(
      planId: planId,
      day: day,
      userId: userId,
      completed: completed,
    );
  }
}
