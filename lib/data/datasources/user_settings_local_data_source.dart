import 'package:shared_preferences/shared_preferences.dart';

class UserSettingsLocalDataSource {
  static const keyTheme = 'settings_theme';
  static const keyLang = 'settings_lang';
  static const keyTextScale = 'settings_text_scale';
  static const keyNotifs = 'settings_notifications';
  static const keyVerse = 'settings_verse_reminder';
  static const keyPlan = 'settings_plan_reminder';
  static const keyDnd = 'settings_dnd';
  static const keyAvatar = 'settings_profile_image';
   // Fondo de perfil (solo ruta local)
  static const keyProfileBg = 'profile_bg';

  Future<Map<String, Object?>> loadRaw() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      keyTheme: prefs.getString(keyTheme),
      keyLang: prefs.getString(keyLang),
      keyTextScale: prefs.getDouble(keyTextScale),
      keyNotifs: prefs.getBool(keyNotifs),
      keyVerse: prefs.getBool(keyVerse),
      keyPlan: prefs.getBool(keyPlan),
      keyDnd: prefs.getBool(keyDnd),
      keyAvatar: prefs.getString(keyAvatar),
      keyProfileBg: prefs.getString(keyProfileBg),
    };
  }

  Future<void> saveRaw(Map<String, Object?> data) async {
    final prefs = await SharedPreferences.getInstance();

    final theme = data[keyTheme];
    if (theme is String) {
      await prefs.setString(keyTheme, theme);
    }

    final lang = data[keyLang];
    if (lang is String) {
      await prefs.setString(keyLang, lang);
    }

    final textScale = data[keyTextScale];
    if (textScale is double) {
      await prefs.setDouble(keyTextScale, textScale);
    }

    final notifs = data[keyNotifs];
    if (notifs is bool) {
      await prefs.setBool(keyNotifs, notifs);
    }

    final verse = data[keyVerse];
    if (verse is bool) {
      await prefs.setBool(keyVerse, verse);
    }

    final plan = data[keyPlan];
    if (plan is bool) {
      await prefs.setBool(keyPlan, plan);
    }

    final dnd = data[keyDnd];
    if (dnd is bool) {
      await prefs.setBool(keyDnd, dnd);
    }

    final avatar = data[keyAvatar];
    if (avatar == null) {
      await prefs.remove(keyAvatar);
    } else if (avatar is String) {
      await prefs.setString(keyAvatar, avatar);
    }

    final bg = data[keyProfileBg];
    if (bg == null) {
      await prefs.remove(keyProfileBg);
    } else if (bg is String) {
      await prefs.setString(keyProfileBg, bg);
    }
  }
}
