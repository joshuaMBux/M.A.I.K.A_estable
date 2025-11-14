# 📋 INFORME COMPLETO: API de Rasa en Maika App

## 🎯 Resumen Ejecutivo

Esta aplicación Flutter está configurada para conectarse con un modelo de Rasa a través de una API REST. El sistema incluye una pantalla de testing dedicada, configuración robusta y manejo de errores completo.

---

## 🏗️ Arquitectura de la API

### **Estructura de Archivos:**
```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart      # Configuración general
│   │   └── rasa_config.dart        # Configuración específica de Rasa
│   └── network/
│       └── api_client.dart         # Cliente HTTP para Rasa
├── data/
│   ├── models/
│   │   └── chat_message_model.dart # Modelo de mensajes
│   └── repositories/
│       └── chat_repository_impl.dart # Implementación del repositorio
├── domain/
│   ├── entities/
│   │   └── chat_message.dart       # Entidad de mensajes
│   └── repositories/
│       └── chat_repository.dart    # Interfaz del repositorio
└── presentation/
    └── pages/
        └── testing/
            └── rasa_test_screen.dart # Pantalla de testing
```

---

## 🔧 Configuración de la API

### **1. Configuración de Rasa (`lib/core/constants/rasa_config.dart`)**

```dart
class RasaConfig {
  // URLs de Rasa para diferentes entornos
  static const String localRasaUrl = 'http://localhost:5005/webhooks/rest/webhook';
  static const String dockerRasaUrl = 'http://localhost:5005/webhooks/rest/webhook';
  static const String cloudRasaUrl = 'https://your-rasa-instance.com/webhooks/rest/webhook';
  
  // URL actual que se está usando
  static const String currentRasaUrl = localRasaUrl;
  
  // Configuración de timeouts
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration responseTimeout = Duration(seconds: 30);
  
  // Configuración de reintentos
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Headers por defecto
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Mensajes de prueba predefinidos
  static const List<String> testMessages = [
    'hola',
    '¿cómo estás?',
    'cuéntame sobre la biblia',
    '¿qué versículos conoces?',
    'gracias por tu ayuda',
    '¿puedes ayudarme con un versículo?',
    'explica Juan 3:16',
    '¿qué dice la biblia sobre el amor?',
  ];
  
  // Configuración de logging
  static const bool enableLogging = true;
  static const bool logRequests = true;
  static const bool logResponses = true;
  static const bool logErrors = true;
  
  // Configuración de debugging
  static const bool enableDebugMode = true;
  static const bool showRawResponses = false;
}
```

### **2. Cliente API (`lib/core/network/api_client.dart`)**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../constants/rasa_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();

  Future<dynamic> post(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      if (RasaConfig.enableLogging && RasaConfig.logRequests) {
        print('🌐 API Request to: $url');
        print('📤 Request body: ${jsonEncode(body)}');
      }

      final response = await _client
          .post(
            Uri.parse(url),
            headers: {...RasaConfig.defaultHeaders, ...?headers},
            body: jsonEncode(body),
          )
          .timeout(RasaConfig.responseTimeout);

      if (RasaConfig.enableLogging && RasaConfig.logResponses) {
        print('📥 Response status: ${response.statusCode}');
        print('📥 Response body: ${response.body}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'HTTP Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (RasaConfig.enableLogging && RasaConfig.logErrors) {
        print('❌ API Error: $e');
      }
      throw Exception('Network Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> sendMessageToRasa(
    String message,
    String sender, {
    String? customUrl,
  }) async {
    final url = customUrl ?? RasaConfig.currentRasaUrl;

    if (!RasaConfig.isValidRasaUrl(url)) {
      throw Exception('URL de Rasa inválida: $url');
    }

    final response = await post(
      url,
      body: {'sender': sender, 'message': message},
    );

    if (response is List) {
      return (response as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } else {
      return [response as Map<String, dynamic>];
    }
  }

  // Método para probar la conexión con Rasa
  Future<bool> testRasaConnection({String? customUrl}) async {
    try {
      final url = customUrl ?? RasaConfig.currentRasaUrl;
      await sendMessageToRasa('test', 'test_user', customUrl: url);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Método para obtener información de la configuración actual
  Map<String, dynamic> getConnectionInfo() {
    return {
      'currentUrl': RasaConfig.currentRasaUrl,
      'configInfo': RasaConfig.getConfigInfo(),
    };
  }

  void dispose() {
    _client.close();
  }
}
```

---

## 📱 Modelos de Datos

### **1. Entidad ChatMessage (`lib/domain/entities/chat_message.dart`)**

```dart
enum MessageType { user, bot }

class ChatMessage {
  final String id;
  final String message;
  final MessageType type;
  final DateTime timestamp;
  final String? senderId;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.message,
    required this.type,
    required this.timestamp,
    this.senderId,
    this.metadata,
  });
}
```

### **2. Modelo ChatMessageModel (`lib/data/models/chat_message_model.dart`)**

```dart
import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  ChatMessageModel({
    required super.id,
    required super.message,
    required super.type,
    required super.timestamp,
    super.senderId,
    super.metadata,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] == 'user' ? MessageType.user : MessageType.bot,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      senderId: json['senderId'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'type': type == MessageType.user ? 'user' : 'bot',
      'timestamp': timestamp.toIso8601String(),
      'senderId': senderId,
      'metadata': metadata,
    };
  }
}
```

---

## 🔄 Repositorio de Chat

### **1. Interfaz del Repositorio (`lib/domain/repositories/chat_repository.dart`)**

```dart
import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<List<ChatMessage>> sendMessage(String message, String sender);
  Future<List<ChatMessage>> getChatHistory();
  Future<void> saveChatHistory(List<ChatMessage> messages);
  Future<void> clearChatHistory();
}
```

### **2. Implementación del Repositorio (`lib/data/repositories/chat_repository_impl.dart`)**

```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<ChatMessage>> sendMessage(String message, String sender) async {
    try {
      // Enviar mensaje a Rasa
      final responses = await _apiClient.sendMessageToRasa(message, sender);

      final chatMessages = <ChatMessage>[];

      // Agregar mensaje del usuario
      chatMessages.add(
        ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: message,
          type: MessageType.user,
          timestamp: DateTime.now(),
          senderId: sender,
        ),
      );

      // Agregar respuestas de Rasa
      for (final response in responses) {
        if (response['text'] != null) {
          chatMessages.add(
            ChatMessageModel(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_bot',
              message: response['text'] as String,
              type: MessageType.bot,
              timestamp: DateTime.now(),
              metadata: response,
            ),
          );
        }
      }

      // Guardar en historial local
      await saveChatHistory(chatMessages);

      return chatMessages;
    } catch (e) {
      // En caso de error, devolver mensaje de error
      return [
        ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: 'Lo siento, no pude procesar tu mensaje. Inténtalo de nuevo.',
          type: MessageType.bot,
          timestamp: DateTime.now(),
        ),
      ];
    }
  }

  @override
  Future<List<ChatMessage>> getChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('chat_history') ?? [];

    // Por ahora devolver mensaje de bienvenida
    return [
      ChatMessageModel(
        id: 'welcome',
        message: '¡Hola! Soy Maika, tu asistente bíblico personal. ¿En qué puedo ayudarte hoy?',
        type: MessageType.bot,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  @override
  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final history = messages.map((msg) => msg.message).toList();
    await prefs.setStringList('chat_history', history);
  }

  @override
  Future<void> clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
  }
}
```

---

## 🧪 Pantalla de Testing

### **Pantalla de Testing (`lib/presentation/pages/testing/rasa_test_screen.dart`)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../domain/entities/chat_message.dart';

class RasaTestScreen extends StatefulWidget {
  const RasaTestScreen({super.key});

  @override
  State<RasaTestScreen> createState() => _RasaTestScreenState();
}

class _RasaTestScreenState extends State<RasaTestScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiClient _apiClient = ApiClient();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _connectionStatus = 'Desconectado';
  String _lastError = '';

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    _testConnection();
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessageModel(
        id: 'welcome',
        message: '🔧 Pantalla de Testing de Rasa API\n\n'
                'Esta pantalla te permite probar la conexión con tu modelo de Rasa.\n'
                'URL configurada: ${AppConstants.rasaWebhookUrl}\n\n'
                'Escribe un mensaje y presiona enviar para probar la API.',
        type: MessageType.bot,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Probando conexión...';
    });

    try {
      // Enviar un mensaje de prueba
      final response = await _apiClient.sendMessageToRasa('hola', 'test_user');

      setState(() {
        _connectionStatus = '✅ Conectado';
        _lastError = '';
      });

      // Agregar respuesta de prueba
      if (response.isNotEmpty) {
        _addBotMessage('✅ Conexión exitosa! Rasa respondió correctamente.');
      }
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ Error de conexión';
        _lastError = e.toString();
      });

      _addBotMessage('❌ Error de conexión: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addBotMessage(String message) {
    setState(() {
      _messages.add(
        ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: message,
          type: MessageType.bot,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();
  }

  void _addUserMessage(String message) {
    setState(() {
      _messages.add(
        ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: message,
          type: MessageType.user,
          timestamp: DateTime.now(),
          senderId: 'test_user',
        ),
      );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _addUserMessage(message);
    _messageController.clear();

    setState(() {
      _isLoading = true;
    });

    try {
      final responses = await _apiClient.sendMessageToRasa(
        message,
        'test_user',
      );

      if (responses.isNotEmpty) {
        for (final response in responses) {
          if (response['text'] != null) {
            _addBotMessage(response['text'] as String);
          }
        }
      } else {
        _addBotMessage('⚠️ Rasa no devolvió ninguna respuesta');
      }
    } catch (e) {
      _addBotMessage('❌ Error: $e');
      setState(() {
        _lastError = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
    _addWelcomeMessage();
  }

  void _sendTestMessages() async {
    final testMessages = [
      'hola',
      '¿cómo estás?',
      'cuéntame sobre la biblia',
      '¿qué versículos conoces?',
      'gracias por tu ayuda',
    ];

    for (final message in testMessages) {
      _messageController.text = message;
      await _sendMessage();
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Testing Rasa API'),
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _testConnection,
            tooltip: 'Probar conexión',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearChat,
            tooltip: 'Limpiar chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Icon(
                  _connectionStatus.contains('✅')
                      ? Icons.check_circle
                      : _connectionStatus.contains('❌')
                      ? Icons.error
                      : Icons.pending,
                  color: _connectionStatus.contains('✅')
                      ? Colors.green
                      : _connectionStatus.contains('❌')
                      ? Colors.red
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _connectionStatus,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_lastError.isNotEmpty)
                        Text(
                          _lastError,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Quick Test Buttons
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendTestMessages,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Enviar Tests'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testConnection,
                    icon: const Icon(Icons.wifi),
                    label: const Text('Probar Conexión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.type == MessageType.user;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment:
                        isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        CircleAvatar(
                          backgroundColor: const Color(
                            AppConstants.primaryColor,
                          ),
                          child: Text(
                            '🤖',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                isUser
                                    ? const Color(AppConstants.primaryColor)
                                    : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message.message,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: const Icon(Icons.person, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Input Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje para probar Rasa...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon:
                      _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(AppConstants.primaryColor),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
```

---

## 🔗 Integración en la Aplicación Principal

### **Navegación Principal (`lib/presentation/pages/main/main_app.dart`)**

```dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../home/home_screen.dart';
import '../explore/explore_screen.dart';
import '../chat/chat_screen.dart';
import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';
import '../testing/rasa_test_screen.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const ChatScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
    const RasaTestScreen(), // Pantalla de testing agregada
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(AppConstants.primaryColor),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'Explorar',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favoritos',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
            BottomNavigationBarItem(icon: Icon(Icons.science), label: 'Test'),
          ],
        ),
      ),
    );
  }
}
```

---

## 📊 Formato de Datos de la API

### **Request a Rasa:**
```json
{
  "sender": "test_user",
  "message": "hola"
}
```

### **Response de Rasa:**
```json
[
  {
    "recipient_id": "test_user",
    "text": "¡Hola! Soy tu asistente espiritual. ¿En qué puedo ayudarte hoy?"
  }
]
```

### **Manejo de Errores:**
```json
{
  "error": "Network Error: Connection refused",
  "status": "error"
}
```

---

## ⚙️ Configuración para Ajustes del Modelo

### **1. Cambiar URL de Rasa:**
En `lib/core/constants/rasa_config.dart`:
```dart
static const String currentRasaUrl = 'http://tu-nueva-url:5005/webhooks/rest/webhook';
```

### **2. Ajustar Timeouts:**
```dart
static const Duration responseTimeout = Duration(seconds: 60); // Aumentar si es necesario
```

### **3. Agregar Nuevos Mensajes de Prueba:**
```dart
static const List<String> testMessages = [
  'hola',
  '¿cómo estás?',
  'cuéntame sobre la biblia',
  '¿qué versículos conoces?',
  'gracias por tu ayuda',
  // Agregar nuevos mensajes aquí
  'explica el amor de Dios',
  '¿qué dice la biblia sobre la fe?',
];
```

### **4. Configurar Logging:**
```dart
static const bool enableLogging = true;  // true para debugging, false para producción
static const bool logRequests = true;    // Mostrar requests en consola
static const bool logResponses = true;   // Mostrar responses en consola
```

---

## 🚀 Comandos para Ejecutar

### **1. Entrenar Modelo de Rasa:**
```bash
cd C:\Users\HP\Documents\Maika_beta_1
rasa train
```

### **2. Ejecutar Rasa:**
```bash
rasa run --enable-api --cors "*" --port 5005 --model models/20250806-171003-greasy-paint.tar.gz
```

### **3. Ejecutar Flutter:**
```bash
cd C:\Users\HP\Documents\maika_app
flutter run -d windows
```

---

## 🔍 Debugging y Testing

### **1. Verificar Conexión:**
```bash
curl -X POST http://localhost:5005/webhooks/rest/webhook \
  -H "Content-Type: application/json" \
  -d '{"sender": "test_user", "message": "hola"}'
```

### **2. Logs Esperados:**
```
🌐 API Request to: http://localhost:5005/webhooks/rest/webhook
📤 Request body: {"sender":"test_user","message":"hola"}
📥 Response status: 200
📥 Response body: [{"recipient_id":"test_user","text":"¡Hola! Soy tu asistente espiritual..."}]
```

### **3. Errores Comunes:**
- **Connection refused**: Rasa no está ejecutándose
- **HTTP Error: 404**: URL incorrecta
- **Timeout**: Rasa tarda mucho en responder
- **Empty response**: Modelo no entrenado o configuración incorrecta

---

## 📝 Notas para Ajustes del Modelo

1. **Entrenar el modelo** cada vez que hagas cambios en `domain.yml`, `nlu.yml`, o `stories.yml`
2. **Verificar la configuración** en `credentials.yml` y `endpoints.yml`
3. **Probar con la pantalla de testing** antes de integrar en producción
4. **Revisar logs** en la consola para debugging
5. **Ajustar timeouts** según la complejidad de tu modelo

---

## 🎯 Próximos Pasos

1. **Integrar el chat en la pantalla principal**
2. **Implementar persistencia de conversaciones**
3. **Agregar manejo de errores más robusto**
4. **Configurar diferentes entornos (dev, staging, prod)**
5. **Implementar autenticación si es necesario**

---

*Este informe contiene todo el código necesario para entender y modificar la API de Rasa en la aplicación Flutter.*


