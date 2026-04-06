import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/settings/settings_cubit.dart';
import '../../widgets/glass_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Notificaciones'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
            ),
          ),
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              final s = state.settings;
              final textTheme = Theme.of(context).textTheme;
              final primary = Theme.of(context).colorScheme.primary;

              return SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    GlassCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.notifications_active_outlined,
                              color: Color(0xFF10B981),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Alertas y recordatorios',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Controla las notificaciones generales '
                                  'y del plan de lectura.',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GlassCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preferencias',
                            style: textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Notificaciones generales',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            value: s.notificationsEnabled,
                            activeColor: primary,
                            onChanged: (value) => context
                                .read<SettingsCubit>()
                                .setNotificationsEnabled(value),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Versículo del día',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            value: s.verseReminderEnabled,
                            activeColor: primary,
                            onChanged: !s.notificationsEnabled
                                ? null
                                : (value) => context
                                    .read<SettingsCubit>()
                                    .setVerseReminder(value),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Plan de lectura',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            value: s.readingPlanReminderEnabled,
                            activeColor: primary,
                            onChanged: !s.notificationsEnabled
                                ? null
                                : (value) => context
                                    .read<SettingsCubit>()
                                    .setReadingPlanReminder(value),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Modo "No molestar"',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              'Silencia recordatorios en la noche.',
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            value: s.doNotDisturb,
                            activeColor: primary,
                            onChanged: (value) => context
                                .read<SettingsCubit>()
                                .setDoNotDisturb(value),
                          ),
                        ],
                      ),
                    ),
                    GlassCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Estas preferencias se guardan localmente. '
                        'Más adelante podrás conectar esta pantalla con '
                        'flutter_local_notifications para programar '
                        'recordatorios.',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
