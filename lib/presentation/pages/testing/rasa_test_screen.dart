import 'package:flutter/material.dart';
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
        message:
            '🔧 Pantalla de Testing de Rasa API\n\n'
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
    _scrollToBottom();
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
        _addBotMessage('❌ No se recibió respuesta del servidor Rasa.');
      }
    } catch (e) {
      _addBotMessage('❌ Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // Fondo con gradiente sutil
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
            ),
          ),

          // Contenido principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.science,
                            color: Color(0xFFFF6B35),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Testing Rasa API',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Estado: $_connectionStatus',
                                style: TextStyle(
                                  color:
                                      _connectionStatus.contains('✅')
                                          ? const Color(0xFF10B981)
                                          : _connectionStatus.contains('❌')
                                          ? Colors.red
                                          : Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF6B35),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lista de mensajes
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
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
                                  Container(
                                    width: 35,
                                    height: 35,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B35),
                                      borderRadius: BorderRadius.circular(17.5),
                                    ),
                                    child: const Icon(
                                      Icons.science,
                                      color: Colors.white,
                                      size: 20,
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
                                              ? const Color(0xFFFF6B35)
                                              : Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            isUser
                                                ? const Color(0xFFFF6B35)
                                                : Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      message.message,
                                      style: TextStyle(
                                        color:
                                            isUser
                                                ? Colors.white
                                                : Colors.white.withOpacity(0.9),
                                        fontSize: 13,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isUser) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 35,
                                    height: 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(17.5),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Barra de entrada
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Escribe un mensaje de prueba...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(22.5),
                          ),
                          child: IconButton(
                            onPressed: _sendMessage,
                            icon: const Icon(
                              Icons.send,
                              color: Color(0xFFFF6B35),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
