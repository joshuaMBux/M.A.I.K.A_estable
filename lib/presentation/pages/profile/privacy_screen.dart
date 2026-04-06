import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/datasources/user_settings_local_data_source.dart';
import '../../blocs/settings/settings_cubit.dart';
import '../../widgets/glass_card.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<void> _clearLocalData(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // Limpiar solo preferencias de configuración / UI, pero mantener sesión.
    await prefs.remove(UserSettingsLocalDataSource.keyTheme);
    await prefs.remove(UserSettingsLocalDataSource.keyLang);
    await prefs.remove(UserSettingsLocalDataSource.keyTextScale);
    await prefs.remove(UserSettingsLocalDataSource.keyNotifs);
    await prefs.remove(UserSettingsLocalDataSource.keyVerse);
    await prefs.remove(UserSettingsLocalDataSource.keyPlan);
    await prefs.remove(UserSettingsLocalDataSource.keyDnd);
    await prefs.remove(UserSettingsLocalDataSource.keyAvatar);
    await prefs.remove(UserSettingsLocalDataSource.keyProfileBg);

    // Volver a cargar Settings desde valores por defecto / prefs limpias.
    context.read<SettingsCubit>().load();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ajustes y datos visuales limpiados.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Privacidad'),
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
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Política de privacidad',
                        style: textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aquí puedes mostrar un resumen de la política de '
                        'privacidad o abrir una pantalla con el documento '
                        'completo.',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                GlassCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Ver política completa',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          'Puede abrirse en otra pantalla o WebView.',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        onTap: () {
                          // Podrías navegar a otra pantalla o usar un WebView local.
                        },
                      ),
                      const Divider(
                        height: 16,
                        thickness: 0.6,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFF59E0B).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.cleaning_services_outlined,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Limpiar datos locales',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          'SharedPreferences, ajustes y caché local.',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        onTap: () => _clearLocalData(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
