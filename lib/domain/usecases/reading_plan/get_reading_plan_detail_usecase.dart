import '../../entities/reading_plan.dart';
import '../../repositories/reading_plan_repository.dart';

class GetReadingPlanDetailUseCase {
  final ReadingPlanRepository repository;

  GetReadingPlanDetailUseCase(this.repository);

  Future<ReadingPlan> call({required int planId, int? userId}) {
    return repository.getPlanDetail(planId: planId, userId: userId);
  }
}
