import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/user_settings.dart';
import '../../../domain/usecases/settings/get_user_settings_usecase.dart';
import '../../../domain/usecases/settings/update_user_settings_usecase.dart';
import '../theme/theme_cubit.dart';
import '../../../core/services/notification_service.dart';

class SettingsState {
  final UserSettings settings;
  final bool isLoading;
  final bool hasError;

  const SettingsState({
    required this.settings,
    this.isLoading = false,
    this.hasError = false,
  });

  SettingsState copyWith({
    UserSettings? settings,
    bool? isLoading,
    bool? hasError,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
    );
  }
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(
    this._getSettings,
    this._updateSettings,
    this._themeCubit,
    this._notificationService,
  ) : super(const SettingsState(settings: UserSettings.initial)) {
    load();
  }

  final GetUserSettingsUseCase _getSettings;
  final UpdateUserSettingsUseCase _updateSettings;
  final ThemeCubit _themeCubit;
  final NotificationService _notificationService;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, hasError: false));
    try {
      final settings = await _getSettings();
      _applyTheme(settings.themeMode);
      emit(SettingsState(settings: settings));
      await _notificationService.sync(settings);
    } catch (_) {
      emit(state.copyWith(isLoading: false, hasError: true));
    }
  }

  Future<void> _persist(UserSettings settings) async {
    emit(state.copyWith(settings: settings));
    await _updateSettings(settings);
    await _notificationService.sync(settings);
  }

  void setTheme(AppThemeMode mode) {
    final updated = state.settings.copyWith(themeMode: mode);
    _applyTheme(mode);
    _persist(updated);
  }

  void setLanguage(AppLanguage language) {
    _persist(state.settings.copyWith(language: language));
  }

  void setTextScale(double scale) {
    _persist(state.settings.copyWith(textScale: scale));
  }

  void setNotificationsEnabled(bool value) {
    _persist(state.settings.copyWith(notificationsEnabled: value));
  }

  void setVerseReminder(bool value) {
    _persist(state.settings.copyWith(verseReminderEnabled: value));
  }

  void setReadingPlanReminder(bool value) {
    _persist(state.settings
        .copyWith(readingPlanReminderEnabled: value));
  }

  void setDoNotDisturb(bool value) {
    _persist(state.settings.copyWith(doNotDisturb: value));
  }

  void setProfileImagePath(String? path) {
    _persist(state.settings.copyWith(profileImagePath: path));
  }

  void setProfileBackgroundPath(String? path) {
    _persist(state.settings.copyWith(profileBackgroundPath: path));
  }

  void _applyTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        _themeCubit.setTheme(ThemeMode.light);
        break;
      case AppThemeMode.dark:
        _themeCubit.setTheme(ThemeMode.dark);
        break;
      case AppThemeMode.system:
        _themeCubit.setTheme(ThemeMode.system);
        break;
    }
  }
}
