# M.A.I.K.A

> Aplicacion movil en Flutter para acompanamiento biblico, chat con avatar, lectura, devocionales y minijuegos.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](#)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](#)
[![Android](https://img.shields.io/badge/Android-APK-3DDC84?logo=android&logoColor=white)](#)
[![Estado](https://img.shields.io/badge/Estado-Activo-6B46C1)](#)

M.A.I.K.A es la app principal de este repositorio. Aqui vive el proyecto Flutter que genera el APK para usuarios finales.

Los repos auxiliares o carpetas tecnicas como `Maika_beta_1` y `maika_avatar` no forman parte del build principal que se distribuye desde este repo.

## Vista Rapida

- Chat biblico con Maika
- Avatar emocional en tiempo real
- Devocionales y plan de lectura
- Favoritos de versiculos y conversaciones
- Audio Biblia
- Minijuegos y gamificacion
- Tema claro y oscuro
- Perfil y ajustes de usuario

## Capturas

Pon tus imagenes en:

```text
docs/images/
```

Nombres recomendados:

- `cover.png`
- `home.png`
- `chat.png`
- `avatar-chat.png`
- `avatar-cha overclok.png`
- `explore.png`
- `game.png`
- `game biblia fragmentada.png`
- `profile.png`

Cuando las agregues, este bloque ya las mostrara automaticamente:

![Portada](docs/images/cover.png)

| Inicio | Chat | Explorar |
|---|---|---|
| ![Inicio](docs/images/home.png) | ![Chat](docs/images/chat.png) | ![Explorar](docs/images/explore.png) |

| Avatar | Avatar Overclock | Perfil |
|---|---|---|
| ![Avatar](docs/images/avatar-chat.png) | ![Avatar Overclock](docs/images/avatar-cha%20overclok.png) | ![Perfil](docs/images/profile.png) |

| Juegos | Biblia Fragmentada |
|---|---|
| ![Juegos](docs/images/game.png) | ![Biblia Fragmentada](docs/images/game%20biblia%20fragmentada.png) |

## Descargar APK

La forma recomendada de descargar la app es desde la seccion `Releases` de este repositorio.

Archivo esperado:

```text
app-release.apk
```

Ruta del build local:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Ejecutar El Proyecto

### Desarrollo

```powershell
flutter pub get
flutter run
```

### APK debug

```powershell
flutter build apk --debug
```

### APK release

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

## Requisitos

- Flutter 3.x
- Dart 3.x
- Android Studio o Android SDK
- Java 17

## Modulos Principales

### Chat y avatar

- Chat biblico con respuestas contextuales
- Avatar emocional con variantes normales y overclock
- Integracion con Rasa y backend extendido

Archivos clave:

- `lib/presentation/pages/chat/chat_screen.dart`
- `lib/presentation/pages/chat/avatar_chat_screen.dart`
- `lib/presentation/pages/chat/avatar_widget.dart`

### Lectura y contenido biblico

- Exploracion de versiculos
- Favoritos
- Devocionales
- Plan de lectura

Archivos clave:

- `lib/presentation/pages/explore/explore_screen.dart`
- `lib/presentation/pages/devotional/devotional_screen.dart`
- `lib/presentation/pages/reading_plan/reading_plan_screen.dart`

### Juegos

- Pantalla de minijuegos
- Estadisticas
- Juego principal "Maika y la Biblia Fragmentada"

Archivos clave:

- `lib/presentation/pages/games/games_screen.dart`
- `lib/presentation/pages/games/game_stats_screen.dart`
- `lib/presentation/games/maika_fragmentada/`

## Stack Tecnologico

- Flutter
- Dart
- flutter_bloc
- SQLite
- shared_preferences
- Flame
- Rasa
- OpenRouter backend

## Estructura Del Proyecto

```text
lib/
  core/           configuracion, servicios, tema, utilidades
  data/           modelos, repositorios y data sources
  domain/         entidades y casos de uso
  presentation/   UI, blocs, widgets, juegos y pantallas
  main.dart       punto de entrada
```

## Backend Y Configuracion

Algunas funciones dependen de servicios externos:

- Rasa: `lib/core/constants/rasa_config.dart`
- Overclock backend: `lib/core/constants/openrouter_backend_config.dart`

Si esos servicios no estan disponibles, la app puede seguir funcionando parcialmente, pero el chat avanzado no respondera igual que en el entorno completo.

## Tema Visual

La app incluye soporte para tema claro y oscuro en la mayor parte de las pantallas principales.

Archivos clave:

- `lib/core/theme/app_theme.dart`
- `lib/core/theme/theme_extensions.dart`
- `lib/presentation/blocs/theme/theme_cubit.dart`

## Estado Del Proyecto

Este repositorio esta orientado a:

- uso academico
- prototipado funcional
- iteracion rapida del producto

Antes de publicarlo en una tienda, conviene revisar:

- firma release propia
- endpoints productivos
- pruebas finales
- limpieza de configuraciones locales

## Licencia

Proyecto de uso educativo y de investigacion.
