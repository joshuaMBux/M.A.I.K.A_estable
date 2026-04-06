import '../../entities/user_settings.dart';
import '../../repositories/user_settings_repository.dart';

class GetUserSettingsUseCase {
  GetUserSettingsUseCase(this._repository);

  final UserSettingsRepository _repository;

  Future<UserSettings> call() => _repository.load();
}

