import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/user_settings.dart';
import '../../blocs/settings/settings_cubit.dart';
import '../../widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Configuración'),
      ),
      body: Stack(
        children: [
          // Fondo degradado coherente con la pantalla de perfil.
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
              final settings = state.settings;
              final textTheme = Theme.of(context).textTheme;

              return SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header
                    GlassCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B46C1)
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.tune,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Personalización',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Tema, idioma y tamaño de texto',
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
                    // Apariencia
                    GlassCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Apariencia',
                            style: textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<AppThemeMode>(
                            segments: const [
                              ButtonSegment(
                                value: AppThemeMode.light,
                                label: Text('Claro'),
                              ),
                              ButtonSegment(
                                value: AppThemeMode.dark,
                                label: Text('Oscuro'),
                              ),
                              ButtonSegment(
                                value: AppThemeMode.system,
                                label: Text('Sistema'),
                              ),
                            ],
                            selected: {settings.themeMode},
                            onSelectionChanged: (value) {
                              context
                                  .read<SettingsCubit>()
                                  .setTheme(value.first);
                            },
                          ),
                        ],
                      ),
                    ),
                    // Idioma
                    GlassCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Idioma',
                            style: textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<AppLanguage>(
                              dropdownColor: const Color(0xFF151A33),
                              value: settings.language,
                              onChanged: (value) {
                                if (value != null) {
                                  context
                                      .read<SettingsCubit>()
                                      .setLanguage(value);
                                }
                              },
                              items: const [
                                DropdownMenuItem(
                                  value: AppLanguage.system,
                                  child: Text('Según sistema'),
                                ),
                                DropdownMenuItem(
                                  value: AppLanguage.es,
                                  child: Text('Español'),
                                ),
                                DropdownMenuItem(
                                  value: AppLanguage.en,
                                  child: Text('Inglés'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tamaño de texto
                    GlassCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tamaño de texto',
                            style: textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Slider(
                            value: settings.textScale,
                            min: 0.8,
                            max: 1.4,
                            divisions: 6,
                            label: settings.textScale.toStringAsFixed(2),
                            onChanged: (value) {
                              context.read<SettingsCubit>().setTextScale(value);
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Escala actual: '
                            '${settings.textScale.toStringAsFixed(2)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
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
