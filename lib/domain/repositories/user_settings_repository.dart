import '../entities/user_settings.dart';

abstract class UserSettingsRepository {
  Future<UserSettings> load();
  Future<void> save(UserSettings settings);
}

