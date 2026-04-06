import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/user_settings_repository.dart';
import '../datasources/user_settings_local_data_source.dart';

class UserSettingsRepositoryImpl implements UserSettingsRepository {
  UserSettingsRepositoryImpl(this._local);

  final UserSettingsLocalDataSource _local;

  @override
  Future<UserSettings> load() async {
    final raw = await _local.loadRaw();

    var settings = UserSettings.initial;

    final theme = raw[UserSettingsLocalDataSource.keyTheme] as String?;
    if (theme != null) {
      final mode = AppThemeMode.values
          .where((m) => m.name == theme)
          .cast<AppThemeMode?>()
          .firstWhere((m) => m != null, orElse: () => null);
      if (mode != null) {
        settings = settings.copyWith(themeMode: mode);
      }
    }

    final lang = raw[UserSettingsLocalDataSource.keyLang] as String?;
    if (lang != null) {
      final language = AppLanguage.values
          .where((l) => l.name == lang)
          .cast<AppLanguage?>()
          .firstWhere((l) => l != null, orElse: () => null);
      if (language != null) {
        settings = settings.copyWith(language: language);
      }
    }

    final textScale =
        raw[UserSettingsLocalDataSource.keyTextScale] as double?;
    if (textScale != null) {
      settings = settings.copyWith(textScale: textScale);
    }

    final notifs = raw[UserSettingsLocalDataSource.keyNotifs] as bool?;
    if (notifs != null) {
      settings = settings.copyWith(notificationsEnabled: notifs);
    }

    final verse = raw[UserSettingsLocalDataSource.keyVerse] as bool?;
    if (verse != null) {
      settings = settings.copyWith(verseReminderEnabled: verse);
    }

    final plan = raw[UserSettingsLocalDataSource.keyPlan] as bool?;
    if (plan != null) {
      settings = settings.copyWith(readingPlanReminderEnabled: plan);
    }

    final dnd = raw[UserSettingsLocalDataSource.keyDnd] as bool?;
    if (dnd != null) {
      settings = settings.copyWith(doNotDisturb: dnd);
    }

    final avatar = raw[UserSettingsLocalDataSource.keyAvatar] as String?;
    if (avatar != null && avatar.isNotEmpty) {
      settings = settings.copyWith(profileImagePath: avatar);
    }

    final bg =
        raw[UserSettingsLocalDataSource.keyProfileBg] as String?;
    if (bg != null && bg.isNotEmpty) {
      settings = settings.copyWith(profileBackgroundPath: bg);
    }

    return settings;
  }

  @override
  Future<void> save(UserSettings settings) {
    return _local.saveRaw({
      UserSettingsLocalDataSource.keyTheme: settings.themeMode.name,
      UserSettingsLocalDataSource.keyLang: settings.language.name,
      UserSettingsLocalDataSource.keyTextScale: settings.textScale,
      UserSettingsLocalDataSource.keyNotifs: settings.notificationsEnabled,
      UserSettingsLocalDataSource.keyVerse: settings.verseReminderEnabled,
      UserSettingsLocalDataSource.keyPlan:
          settings.readingPlanReminderEnabled,
      UserSettingsLocalDataSource.keyDnd: settings.doNotDisturb,
      UserSettingsLocalDataSource.keyAvatar: settings.profileImagePath,
      UserSettingsLocalDataSource.keyProfileBg:
          settings.profileBackgroundPath,
    });
  }
}
