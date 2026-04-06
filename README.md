# M.A.I.K.A - Asistente Bíblico Personal

**M.A.I.K.A** (Asistente Inteligente de Conocimiento Bíblico) es una aplicación móvil desarrollada en **Flutter** que funciona como tu asistente bíblico personal con inteligencia artificial. El nombre es un acrónimo que representa el enfoque en la Biblia como guía espiritual.

## Características

- **Chat con IA**: Conversa con Maika sobre temas bíblicos, oraciones, devocionales y más
- **Avatar Interactivo**: Un avatar anime 2D que responde con diferentes emociones
- **Plan de Lectura**: Planes de lectura bíblica diarios con seguimiento de progreso
- **Devocionales**: Devocionales diarios basados en la Palabra de Dios
- **Favoritos**: Guarda versículos y mensajes importantes
- **Explorar**: Explora la Biblia por libros, categorías y versículos
- **Audiolibro**: Reproduce la Biblia en audio (módulos de audio)
- **Perfil de Usuario**: Configura idioma, notificaciones, tamaño de texto y más
- **Modo Oscuro**: Soporte completo para tema claro y oscuro
- **Juegos**: Minijuegos para aprender la Biblia

## Tecnologías

- **Flutter**: Framework principal (Dart)
- **Rasa NLU**: Servicio de procesamiento de lenguaje natural
- **SQLite**: Base de datos local
- **BLoC**: Gestión de estado
- **GetIt**: Inyección de dependencias
- **Share Plus**: Compartir contenido

## Estructura del Proyecto

```
lib/
├── core/                  # Configuraciones, constantes, temas
├── data/                  # Repositorios, modelos, fuentes de datos
├── domain/                # Entidades, repositorios (interfaces), casos de uso
├── presentation/          # UI, BLoCs, pantallas, widgets
└── main.dart             # Punto de entrada
```

## Ejecutar en Desarrollo

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en emulador/dispositivo
flutter run

# Build para Android
flutter build apk --debug
```

## Configuración de Rasa

Para el chat con IA, necesitas un servidor Rasa ejecutándose. Configura la URL en `lib/core/constants/rasa_config.dart`:

- Emulador Android: `http://10.0.2.2:5005/webhooks/rest/webhook`
- iOS Simulator: `http://127.0.0.1:5005/webhooks/rest/webhook`
- Docker: `http://localhost:5005/webhooks/rest/webhook`

## Emociones del Avatar

El avatar soporta múltiples emociones que cambian según el contexto de la conversación:
- neutral, feliz, triste, nerviosa, sorprendida
- inspirada, pensativa, sonrojada, aliviada
- cansada, aburrida, orgullosa, picara, bufona
- enojada, dudando, orando, feliz_logro

## Licencia

Este proyecto es para fines educativos y de investigación.