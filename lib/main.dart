import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'domain/entities/user_settings.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/chat/chat_bloc.dart';
import 'presentation/blocs/favorites/favorites_bloc.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/blocs/settings/settings_cubit.dart';
import 'presentation/pages/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MaikaApp());
}

class MaikaApp extends StatelessWidget {
  const MaikaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>()..add(CheckAuthStatus()),
        ),
        BlocProvider<ChatBloc>(create: (context) => di.sl<ChatBloc>()),
        BlocProvider<FavoritesBloc>(
          create: (context) => di.sl<FavoritesBloc>(),
        ),
        BlocProvider<ThemeCubit>(create: (context) => di.sl<ThemeCubit>()),
        BlocProvider<SettingsCubit>(create: (context) => di.sl<SettingsCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settingsState) {
              final settings = settingsState.settings;

              Locale? locale;
              switch (settings.language) {
                case AppLanguage.es:
                  locale = const Locale('es');
                  break;
                case AppLanguage.en:
                  locale = const Locale('en');
                  break;
                case AppLanguage.system:
                default:
                  locale = null; // usa idioma del sistema
                  break;
              }

              return Builder(
                builder: (context) {
                  final baseMedia = MediaQuery.of(context);
                  final scaledMedia = baseMedia.copyWith(
                    textScaler: TextScaler.linear(settings.textScale),
                  );

                  return MediaQuery(
                    data: scaledMedia,
                    child: MaterialApp(
                      title: AppConstants.appName,
                      debugShowCheckedModeBanner: false,
                      themeMode: themeMode,
                      theme: AppTheme.light(),
                      darkTheme: AppTheme.dark(),
                      locale: locale,
                      supportedLocales: const [
                        Locale('es'),
                        Locale('en'),
                      ],
                      localizationsDelegates: const [
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                      home: const SplashScreen(),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
