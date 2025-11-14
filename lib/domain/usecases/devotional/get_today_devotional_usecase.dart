import '../../entities/devotional.dart';
import '../../repositories/devotional_repository.dart';

class GetTodayDevotionalUseCase {
  final DevotionalRepository repository;

  GetTodayDevotionalUseCase(this.repository);

  Future<Devotional?> call() {
    return repository.getTodayDevotional();
  }
}
