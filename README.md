# 📱 Maika App - Tu Compañero Bíblico Inteligente

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-3.16.0-blue?style=for-the-badge&logo=flutter" alt="Flutter Version">
  <img src="https://img.shields.io/badge/Dart-3.2.0-blue?style=for-the-badge&logo=dart" alt="Dart Version">
  <img src="https://img.shields.io/badge/Rasa-3.6.0-orange?style=for-the-badge&logo=rasa" alt="Rasa Version">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License">
</div>

<br>

<div align="center">
  <h3>🚀 Aplicación Flutter con Integración de IA Conversacional</h3>
  <p>Una aplicación móvil moderna que combina la lectura bíblica con inteligencia artificial para crear una experiencia espiritual interactiva y personalizada.</p>
</div>

---

## 🌟 Características Principales

### 🤖 **Chat Inteligente con IA**
- **Modo Avatar**: Interfaz inmersiva con avatar 3D y controles de voz
- **Modo Chat**: Conversación tradicional por texto
- **Integración Rasa**: Respuestas inteligentes y contextuales
- **Historial Persistente**: Guardado local de conversaciones

### 📖 **Gestión Bíblica Completa**
- **Exploración por Categorías**: Amor, fe, esperanza, paz, etc.
- **Búsqueda Avanzada**: Encuentra versículos específicos
- **Sistema de Favoritos**: Guarda tus versículos preferidos
- **Versículo del Día**: Inspiración diaria personalizada

### 🎯 **Seguimiento de Progreso**
- **Dashboard Personal**: Estadísticas de uso
- **Progreso Diario**: Barra de progreso y porcentajes
- **Sistema de Streak**: 7 días consecutivos de uso
- **Logros y Metas**: Motivación constante

### 🎨 **Interfaz Moderna**
- **Diseño Glassmorphism**: Efectos translúcidos y modernos
- **Tema Oscuro**: Experiencia visual cómoda
- **Responsive Design**: Adaptable a diferentes pantallas
- **Navegación Intuitiva**: Bottom navigation personalizada

---

## 🏗️ Arquitectura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── core/                        # Funcionalidades centrales
│   ├── constants/               # Configuración global
│   ├── di/                      # Inyección de dependencias
│   └── network/                 # Capa de red
├── data/                        # Capa de datos
│   ├── models/                  # Modelos de datos
│   └── repositories/            # Implementaciones
├── domain/                      # Lógica de negocio
│   ├── entities/                # Entidades del dominio
│   ├── repositories/            # Interfaces
│   └── usecases/                # Casos de uso
└── presentation/                # Capa de presentación
    ├── blocs/                   # Gestión de estado
    └── pages/                   # Pantallas de la app
```

---

## 🚀 Instalación y Configuración

### 📋 Prerrequisitos

- **Flutter SDK**: 3.16.0 o superior
- **Dart**: 3.2.0 o superior
- **Android Studio** / **VS Code**
- **Rasa**: 3.6.0 o superior (para el backend de IA)

### 🔧 Instalación

1. **Clonar el repositorio**
```bash
git clone https://github.com/joshuaMBux/Maika_APP_UI.git
cd Maika_APP_UI
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Configurar Rasa (Opcional)**
```bash
# Navegar al directorio de Rasa
cd ../Maika_beta_1

# Entrenar el modelo
rasa train

# Ejecutar el servidor
rasa run --enable-api --cors "*" --port 5005
```

4. **Ejecutar la aplicación**
```bash
flutter run
```

---

## ⚙️ Configuración

### 🔗 Configuración de Rasa

Edita `lib/core/constants/rasa_config.dart`:

```dart
class RasaConfig {
  // URLs de conexión
  static const String localRasaUrl = 'http://localhost:5005';
  static const String dockerRasaUrl = 'http://rasa:5005';
  static const String cloudRasaUrl = 'https://tu-rasa-cloud.com';
  
  // URL actual (cambiar según tu configuración)
  static const String currentRasaUrl = localRasaUrl;
}
```

### 🌐 Configuración de Red

Ajusta timeouts y reintentos en `lib/core/network/api_client.dart`:

```dart
// Timeouts configurables
static const Duration connectionTimeout = Duration(seconds: 10);
static const Duration responseTimeout = Duration(seconds: 30);
static const int maxRetries = 3;
```

---

## 📱 Pantallas de la Aplicación

### 🏠 **Pantalla de Inicio**
- Dashboard con progreso diario
- Tarjetas de acción principales y secundarias
- Versículo del día
- Estadísticas de uso

### 💬 **Pantalla de Chat**
- **Modo Avatar**: Interfaz inmersiva con controles de voz
- **Modo Chat**: Conversación tradicional
- Toggle entre modos
- Historial de mensajes

### 🔍 **Pantalla de Exploración**
- Búsqueda de versículos
- Filtros por categorías
- Navegación intuitiva
- Resultados paginados

### ❤️ **Pantalla de Favoritos**
- Lista de versículos guardados
- Gestión de favoritos
- Búsqueda en favoritos

### 👤 **Pantalla de Perfil**
- Información del usuario
- Configuración de cuenta
- Estadísticas personales
- Opciones de configuración

### 🧪 **Pantalla de Pruebas**
- Pruebas de conexión con Rasa
- Logs de API
- Estado de conexión
- Mensajes de prueba

---

## 🤖 Integración con Rasa

### 📡 Endpoints Utilizados

- **Webhook**: `/webhooks/rest/webhook`
- **Método**: POST
- **Formato**: JSON

### 📝 Ejemplo de Request

```json
{
  "sender": "user123",
  "message": "Hola, ¿cómo estás?"
}
```

### 📝 Ejemplo de Response

```json
[
  {
    "recipient_id": "user123",
    "text": "¡Hola! Estoy muy bien, gracias por preguntar. ¿En qué puedo ayudarte hoy?"
  }
]
```

### 🔧 Configuración del Servidor Rasa

```bash
# Entrenar modelo
rasa train

# Ejecutar servidor
rasa run --enable-api --cors "*" --port 5005 --model models/latest.tar.gz

# Verificar conexión
curl -X POST http://localhost:5005/webhooks/rest/webhook \
  -H "Content-Type: application/json" \
  -d '{"sender": "test", "message": "hola"}'
```

---

## 🛠️ Tecnologías Utilizadas

### 📱 **Frontend**
- **Flutter**: Framework de desarrollo móvil
- **Dart**: Lenguaje de programación
- **flutter_bloc**: Gestión de estado
- **get_it**: Inyección de dependencias

### 🌐 **Backend & APIs**
- **Rasa**: Framework de IA conversacional
- **HTTP**: Cliente para comunicación con APIs
- **SharedPreferences**: Almacenamiento local

### 🎨 **UI/UX**
- **Material Design**: Componentes de interfaz
- **Glassmorphism**: Efectos visuales modernos
- **Responsive Design**: Adaptabilidad multiplataforma

---

## 📊 Estado del Proyecto

### ✅ **Completado**
- [x] Arquitectura completa (Clean Architecture)
- [x] Todas las pantallas implementadas
- [x] Integración con Rasa API
- [x] Diseño visual moderno
- [x] Navegación funcional
- [x] Gestión de estado con BLoC
- [x] Persistencia local de datos
- [x] Sistema de favoritos
- [x] Búsqueda y filtros
- [x] Modo dual en chat (Avatar/Chat)

### 🔄 **En Desarrollo**
- [ ] Funcionalidad completa de botones en tarjetas
- [ ] Integración de autenticación de usuarios
- [ ] Sincronización en la nube
- [ ] Notificaciones push

### 🚀 **Próximas Funcionalidades**
- [ ] Sistema de notificaciones
- [ ] Modo offline completo
- [ ] Personalización de temas
- [ ] Exportación de datos
- [ ] Compartir versículos
- [ ] Audio de versículos

---

## 🧪 Testing

### 🔍 **Pruebas de API**

Utiliza la pantalla de pruebas integrada o ejecuta:

```bash
# Probar conexión con Rasa
curl -X POST http://localhost:5005/webhooks/rest/webhook \
  -H "Content-Type: application/json" \
  -d '{"sender": "test", "message": "hola"}'
```

### 📱 **Pruebas de la Aplicación**

```bash
# Ejecutar tests unitarios
flutter test

# Ejecutar tests de widgets
flutter test test/widget_test.dart

# Ejecutar con coverage
flutter test --coverage
```

---

## 📚 Documentación Adicional

- **[RASA_TESTING.md](./RASA_TESTING.md)**: Guía completa para configurar y probar Rasa
- **[INFORME_API_RASA.md](./INFORME_API_RASA.md)**: Reporte técnico detallado de la integración

---

## 🤝 Contribución

1. **Fork** el proyecto
2. **Crea** una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. **Commit** tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. **Push** a la rama (`git push origin feature/AmazingFeature`)
5. **Abre** un Pull Request

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.

---

## 👨‍💻 Autor

**Joshua Bux** - [GitHub](https://github.com/joshuaMBux)

---

## 🙏 Agradecimientos

- **Flutter Team** por el increíble framework
- **Rasa Team** por la plataforma de IA conversacional
- **Comunidad Flutter** por el soporte y recursos

---

<div align="center">
  <p>⭐ Si este proyecto te ayuda, ¡dale una estrella en GitHub!</p>
  <p>📧 Contacto: [por only]</p>
</div>
