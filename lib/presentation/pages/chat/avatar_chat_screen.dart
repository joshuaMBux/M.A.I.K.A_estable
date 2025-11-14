import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../domain/entities/chat_message.dart';

class AvatarChatScreen extends StatefulWidget {
  const AvatarChatScreen({super.key});

  @override
  State<AvatarChatScreen> createState() => _AvatarChatScreenState();
}

class _AvatarChatScreenState extends State<AvatarChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ApiClient _apiClient = ApiClient();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isRecording = false;
  bool _isSpeaking = false;
  bool _isAvatarMode = true; // true = modo avatar, false = modo chat

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessageModel(
        id: 'welcome',
        message:
            '¡Hola! Soy Maika, tu asistente espiritual. ¿En qué puedo ayudarte hoy?',
        type: MessageType.bot,
        timestamp: DateTime.now(),
      ),
    );
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
  }

  void _addUserMessage(String message) {
    setState(() {
      _messages.add(
        ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: message,
          type: MessageType.user,
          timestamp: DateTime.now(),
          senderId: 'user',
        ),
      );
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
      final responses = await _apiClient.sendMessageToRasa(message, 'user');

      if (responses.isNotEmpty) {
        for (final response in responses) {
          if (response['text'] != null) {
            _addBotMessage(response['text'] as String);
          }
        }
      } else {
        _addBotMessage(
          'Lo siento, no pude procesar tu mensaje. Inténtalo de nuevo.',
        );
      }
    } catch (e) {
      _addBotMessage(
        'Error de conexión. Verifica que el servidor esté funcionando.',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
    if (_isRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎤 Grabando... Presiona de nuevo para detener'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏹️ Grabación detenida'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  void _toggleSpeaking() {
    setState(() {
      _isSpeaking = !_isSpeaking;
    });
    if (_isSpeaking) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔊 Modo voz activado'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔇 Modo voz desactivado'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  void _captureImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📸 Función de captura en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _stopAll() {
    setState(() {
      _isRecording = false;
      _isSpeaking = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏹️ Todas las funciones detenidas'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _isAvatarMode = !_isAvatarMode;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isAvatarMode ? '🎭 Modo Avatar activado' : '💬 Modo Chat activado',
        ),
        backgroundColor: const Color(0xFF6B46C1),
      ),
    );
  }

  // Modo Avatar - Interfaz con avatar 3D y controles de voz
  Widget _buildAvatarMode() {
    return Column(
      children: [
        // Área del avatar (placeholder por ahora)
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Placeholder del avatar 3D
                Container(
                  width: 200,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.face,
                        size: 80,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Avatar 3D\nNo Disponible',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Indicador de estado
                if (_isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Procesando...',
                          style: TextStyle(color: Colors.blue, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Modo Chat - Interfaz de mensajes de texto
  Widget _buildChatMode() {
    return Column(
      children: [
        // Lista de mensajes
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isUser = message.type == MessageType.user;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment:
                      isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isUser) ...[
                      // Avatar de Maika para mensajes del bot
                      Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B46C1),
                          borderRadius: BorderRadius.circular(17.5),
                        ),
                        child: const Icon(
                          Icons.smart_toy,
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
                              isUser ? const Color(0xFF6B46C1) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          message.message,
                          style: TextStyle(
                            color:
                                isUser ? Colors.white : const Color(0xFF1A1A2E),
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 8),
                      // Avatar del usuario
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

        // Indicador de carga
        if (_isLoading)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6B46C1).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF6B46C1),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Procesando...',
                  style: TextStyle(color: Color(0xFF6B46C1), fontSize: 14),
                ),
              ],
            ),
          ),
      ],
    );
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
          Column(
            children: [
              // Barra superior con Maika
              Container(
                height: 80,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar de Maika
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B46C1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.smart_toy,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Información de Maika
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Maika',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Asistente Bíblico',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botones de la derecha
                    Row(
                      children: [
                        // Botón de cambio de modo
                        GestureDetector(
                          onTap: _toggleMode,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  _isAvatarMode
                                      ? const Color(0xFF6B46C1).withOpacity(0.3)
                                      : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              _isAvatarMode
                                  ? Icons.face
                                  : Icons.chat_bubble_outline,
                              color:
                                  _isAvatarMode ? Colors.white : Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Área central que cambia según el modo
              Expanded(
                child: _isAvatarMode ? _buildAvatarMode() : _buildChatMode(),
              ),

              // Barra inferior que cambia según el modo
              _isAvatarMode ? _buildAvatarBottomBar() : _buildChatBottomBar(),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // Barra inferior para modo Avatar (con controles de voz)
  Widget _buildAvatarBottomBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          // Botón de cámara
          GestureDetector(
            onTap: _captureImage,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Botón de altavoz
          GestureDetector(
            onTap: _toggleSpeaking,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color:
                    _isSpeaking
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.volume_up,
                color: _isSpeaking ? Colors.blue : Colors.white,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Botón de micrófono
          GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color:
                    _isRecording
                        ? Colors.red.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: _isRecording ? Colors.red : Colors.white,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Campo de texto
          Expanded(
            child: Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask Anything',
                  hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Botón Stop
          GestureDetector(
            onTap: _stopAll,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.stop, color: Colors.red, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // Barra inferior para modo Chat (solo texto)
  Widget _buildChatBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          // Botón de micrófono
          GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFF6B46C1).withOpacity(0.2),
                borderRadius: BorderRadius.circular(22.5),
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: const Color(0xFF6B46C1),
                size: 22,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Campo de texto
          Expanded(
            child: Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(22.5),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Habla con Maika...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Botón de enviar
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFF6B46C1).withOpacity(0.2),
                borderRadius: BorderRadius.circular(22.5),
              ),
              child: const Icon(Icons.send, color: Color(0xFF6B46C1), size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
