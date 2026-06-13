enum AppThemeMode { system, light, dark }
enum AppLanguage { system, es, en }

class UserSettings {
  final AppThemeMode themeMode;
  final AppLanguage language;
  final double textScale;
  final bool notificationsEnabled;
  final bool verseReminderEnabled;
  final bool readingPlanReminderEnabled;
  final bool doNotDisturb;
  final String? profileImagePath;
  final String? profileBackgroundPath;

  const UserSettings({
    required this.themeMode,
    required this.language,
    required this.textScale,
    required this.notificationsEnabled,
    required this.verseReminderEnabled,
    required this.readingPlanReminderEnabled,
    required this.doNotDisturb,
    this.profileImagePath,
    this.profileBackgroundPath,
  });

  static const UserSettings initial = UserSettings(
    themeMode: AppThemeMode.light,
    language: AppLanguage.es,
    textScale: 1.0,
    notificationsEnabled: true,
    verseReminderEnabled: true,
    readingPlanReminderEnabled: false,
    doNotDisturb: false,
    profileImagePath: null,
    profileBackgroundPath: null,
  );

  UserSettings copyWith({
    AppThemeMode? themeMode,
    AppLanguage? language,
    double? textScale,
    bool? notificationsEnabled,
    bool? verseReminderEnabled,
    bool? readingPlanReminderEnabled,
    bool? doNotDisturb,
    String? profileImagePath,
    String? profileBackgroundPath,
  }) {
    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      textScale: textScale ?? this.textScale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      verseReminderEnabled: verseReminderEnabled ?? this.verseReminderEnabled,
      readingPlanReminderEnabled:
          readingPlanReminderEnabled ?? this.readingPlanReminderEnabled,
      doNotDisturb: doNotDisturb ?? this.doNotDisturb,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      profileBackgroundPath:
          profileBackgroundPath ?? this.profileBackgroundPath,
    );
  }
}
