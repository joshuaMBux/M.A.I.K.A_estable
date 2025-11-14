import '../../repositories/reading_plan_repository.dart';

class GetDefaultReadingPlanIdUseCase {
  final ReadingPlanRepository repository;

  GetDefaultReadingPlanIdUseCase(this.repository);

  Future<int?> call() {
    return repository.getDefaultPlanId();
  }
}
