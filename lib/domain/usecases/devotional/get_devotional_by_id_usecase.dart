import '../../entities/devotional.dart';
import '../../repositories/devotional_repository.dart';

class GetDevotionalByIdUseCase {
  final DevotionalRepository repository;

  GetDevotionalByIdUseCase(this.repository);

  Future<Devotional?> call(int id) {
    return repository.getDevotionalById(id);
  }
}
