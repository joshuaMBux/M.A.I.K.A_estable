import '../../entities/user_settings.dart';
import '../../repositories/user_settings_repository.dart';

class UpdateUserSettingsUseCase {
  UpdateUserSettingsUseCase(this._repository);

  final UserSettingsRepository _repository;

  Future<void> call(UserSettings settings) => _repository.save(settings);
}

