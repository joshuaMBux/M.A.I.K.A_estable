import '../../entities/devotional.dart';
import '../../repositories/devotional_repository.dart';

class GetRecentDevotionalsUseCase {
  final DevotionalRepository repository;

  GetRecentDevotionalsUseCase(this.repository);

  Future<List<Devotional>> call({int limit = 10}) {
    return repository.getRecentDevotionals(limit: limit);
  }
}
