import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/user_settings.dart';

abstract class NotificationService {
  Future<void> sync(UserSettings settings);
  Future<void> cancelAll();
  Future<void> cancelVerseOfDay();
  Future<void> cancelReadingPlan();
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService() {
    _init();
  }

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'maika_reminders';
  static const _channelName = 'Recordatorios de Maika';
  static const _channelDescription =
      'Recordatorios simples para animarte a usar la app.';

  static const int _genericReminderId = 1001;

  Future<void> _init() async {
    if (kIsWeb) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);
  }

  NotificationDetails _defaultDetails() {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  @override
  Future<void> sync(UserSettings settings) async {
    if (kIsWeb) return;

    // Si las notificaciones están desactivadas o no hay ningún tipo activo,
    // cancelamos todo.
    final anyReminderEnabled =
        settings.verseReminderEnabled || settings.readingPlanReminderEnabled;
    if (!settings.notificationsEnabled || !anyReminderEnabled) {
      await cancelAll();
      return;
    }

    // Una sola notificación diaria, pero con mensaje ajustado según los toggles.
    await _scheduleGenericDailyReminder(settings);
  }

  Future<void> _scheduleGenericDailyReminder(UserSettings settings) async {
    await _plugin.cancel(_genericReminderId);

    String title;
    String body;

    final verseOn = settings.verseReminderEnabled;
    final planOn = settings.readingPlanReminderEnabled;

    if (verseOn && planOn) {
      title = 'Maika te acompaña hoy';
      body =
          'Revisa tu versículo del día y avanza en tu plan de lectura.';
    } else if (verseOn) {
      title = 'Versículo del día';
      body =
          'Tómate un momento para leer el versículo de hoy con Maika.';
    } else if (planOn) {
      title = 'Plan de lectura';
      body = 'Hoy toca avanzar en tu plan de lectura bíblica.';
    } else {
      title = 'Maika te está esperando';
      body =
          'No olvides repasar la Biblia hoy. Dedica unos minutos a tu fe.';
    }

    await _plugin.periodicallyShow(
      _genericReminderId,
      title,
      body,
      RepeatInterval.daily,
      _defaultDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  @override
  Future<void> cancelVerseOfDay() async {
    if (kIsWeb) return;
    await _plugin.cancel(_genericReminderId);
  }

  @override
  Future<void> cancelReadingPlan() async {
    if (kIsWeb) return;
    await _plugin.cancel(_genericReminderId);
  }
}

