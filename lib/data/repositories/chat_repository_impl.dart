import 'dart:async';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_local_data_source.dart';
import '../datasources/rasa_api.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required ChatLocalDataSource localDataSource,
    required ApiClient apiClient,
    RasaApi? rasaApi,
  }) : _localDataSource = localDataSource,
       _apiClient = apiClient,
       _rasaApi = rasaApi ?? RasaApi(apiClient) {
    _connectionController = StreamController<bool>.broadcast();
    _rasaApi.connectionStream.listen(_connectionController.add);
  }

  final ChatLocalDataSource _localDataSource;
  final ApiClient _apiClient;
  final RasaApi _rasaApi;
  late final StreamController<bool> _connectionController;

  bool _lastConnectionState = false;
  int _messageCounter = 0;

  @override
  Future<ChatSession> loadSession({String? conversationId}) async {
    final id = await _localDataSource.ensureConversation(conversationId);
    final messages = await _localDataSource.getMessages(id);
    final connected = await _rasaApi.checkHealth();
    _lastConnectionState = connected;

    // Seed conversation with welcome message if empty.
    if (messages.isEmpty) {
      final welcome = ChatMessageModel(
        id: _generateMessageId(prefix: 'welcome'),
        conversationId: id,
        text:
            'Hola! Soy Maika, tu asistente biblico. En que parte de la Biblia te gustaria profundizar hoy?',
        type: MessageType.bot,
        contentType: MessageContentType.text,
        status: MessageDeliveryStatus.delivered,
        timestamp: DateTime.now(),
        generated: true,
        quickReplies: const [
          ChatActionChip(
            title: 'Versiculos sobre la fe',
            payload: '/verses_faith',
          ),
          ChatActionChip(
            title: 'Versiculo del dia',
            payload: '/verse_of_the_day',
          ),
        ],
      );
      await _localDataSource.insertMessage(welcome);
      return loadSession(conversationId: id);
    }

    return ChatSession(
      id: id,
      title: AppConstants.appName,
      messages: messages,
      suggestions: _mergeSuggestions(messages),
      isConnected: connected,
      hasPendingMessages: messages.any((m) => m.isPending || m.isError),
      updatedAt: messages.last.timestamp,
    );
  }

  @override
  Future<ChatSession> sendMessage({
    required String conversationId,
    required String text,
    String? payload,
    bool fromSuggestion = false,
  }) async {
    final id = await _localDataSource.ensureConversation(conversationId);
    final now = DateTime.now();
    final outgoingId = _generateMessageId(prefix: 'user');

    final userMessage = ChatMessageModel(
      id: outgoingId,
      conversationId: id,
      text: text,
      type: MessageType.user,
      contentType: MessageContentType.text,
      status: MessageDeliveryStatus.pending,
      timestamp: now,
      senderId: 'user_local',
      metadata: {'payload': payload, 'fromSuggestion': fromSuggestion},
    );

    await _localDataSource.insertMessage(userMessage);

    final rasaMessage = payload?.isNotEmpty == true ? payload! : text;

    try {
      final response = await _rasaApi.sendMessage(
        message: rasaMessage,
        sender: id,
      );
      _lastConnectionState = true;

      await _localDataSource.updateMessageStatus(
        outgoingId,
        MessageDeliveryStatus.delivered,
      );

      final botMessages = _mapRasaPayload(
        response,
        conversationId: id,
        receivedAt: DateTime.now(),
      );
      await _localDataSource.insertMessages(botMessages);
    } catch (_) {
      await _localDataSource.updateMessageStatus(
        outgoingId,
        MessageDeliveryStatus.error,
      );
      _lastConnectionState = false;
    }

    final messages = await _localDataSource.getMessages(id);
    return ChatSession(
      id: id,
      title: AppConstants.appName,
      messages: messages,
      suggestions: _mergeSuggestions(messages),
      isConnected: _lastConnectionState,
      hasPendingMessages: messages.any((m) => m.isPending || m.isError),
      updatedAt: messages.last.timestamp,
    );
  }

  @override
  Future<ChatSession> syncPending(String conversationId) async {
    final pending = await _localDataSource.getPendingMessages(conversationId);
    if (pending.isEmpty) {
      return loadSession(conversationId: conversationId);
    }

    for (final pendingMessage in pending) {
      try {
        final response = await _rasaApi.sendMessage(
          message:
              pendingMessage.metadata?['payload'] as String? ??
              pendingMessage.text,
          sender: conversationId,
        );
        _lastConnectionState = true;
        await _localDataSource.updateMessageStatus(
          pendingMessage.id,
          MessageDeliveryStatus.delivered,
        );
        final botMessages = _mapRasaPayload(
          response,
          conversationId: conversationId,
          receivedAt: DateTime.now(),
        );
        await _localDataSource.insertMessages(botMessages);
      } catch (_) {
        await _localDataSource.updateMessageStatus(
          pendingMessage.id,
          MessageDeliveryStatus.error,
        );
        _lastConnectionState = false;
        break;
      }
    }

    final messages = await _localDataSource.getMessages(conversationId);
    return ChatSession(
      id: conversationId,
      title: AppConstants.appName,
      messages: messages,
      suggestions: _mergeSuggestions(messages),
      isConnected: _lastConnectionState,
      hasPendingMessages: messages.any((m) => m.isPending || m.isError),
      updatedAt: messages.last.timestamp,
    );
  }

  @override
  Future<void> toggleFavorite({
    required String messageId,
    required bool isFavorite,
    String? note,
  }) {
    return _localDataSource.markFavorite(
      messageId: messageId,
      isFavorite: isFavorite,
      note: note,
    );
  }

  @override
  Future<List<ChatMessage>> getFavoriteMessages({
    String? conversationId,
  }) {
    return _localDataSource.getFavoriteMessages(
      conversationId: conversationId,
    );
  }

  @override
  Stream<bool> watchConnection() {
    scheduleMicrotask(() async {
      final healthy = await _apiClient.testRasaConnection();
      _connectionController.add(healthy);
      _lastConnectionState = healthy;
    });
    return _connectionController.stream.distinct();
  }

  @override
  List<ChatActionChip> defaultSuggestions() {
    return _localDataSource.defaultSuggestions();
  }

  List<ChatActionChip> _mergeSuggestions(List<ChatMessage> messages) {
    final fromMessages = messages
        .map((message) => message.quickReplies)
        .expand((chips) => chips)
        .toList();
    final defaults = _localDataSource.defaultSuggestions();

    final payloads = <String>{};
    final merged = <ChatActionChip>[];

    for (final chip in [...fromMessages, ...defaults]) {
      if (chip.payload.isEmpty || payloads.contains(chip.payload)) {
        continue;
      }
      payloads.add(chip.payload);
      merged.add(chip);
    }

    return merged;
  }

  List<ChatMessageModel> _mapRasaPayload(
    List<Map<String, dynamic>> payload, {
    required String conversationId,
    required DateTime receivedAt,
  }) {
    if (payload.isEmpty) {
      return [];
    }

    final messages = <ChatMessageModel>[];

    for (final item in payload) {
      final text = (item['text'] as String?) ?? '';
      final imageUrl = item['image'] as String?;
      final buttonsRaw = item['buttons'] as List<dynamic>?;
      final custom = item['custom'] as Map<String, dynamic>?;

      final quickReplies = buttonsRaw == null
          ? const <ChatActionChip>[]
          : buttonsRaw
                .map(
                  (button) => ChatActionChip(
                    title:
                        (button as Map<String, dynamic>)['title'] as String? ??
                        '',
                    payload: button['payload'] as String? ?? '',
                  ),
                )
                .where(
                  (chip) => chip.title.isNotEmpty && chip.payload.isNotEmpty,
                )
                .toList();

      List<ChatListItem> listItems = const [];
      MessageContentType contentType = MessageContentType.text;
      String messageText = text;

      if (imageUrl != null) {
        contentType = MessageContentType.image;
        if (messageText.isEmpty) {
          messageText = 'Imagen generada por Maika';
        }
      }

      if (custom != null) {
        final customType = custom['type'] as String?;
        if (customType == 'list') {
          final items = custom['items'] as List<dynamic>? ?? [];
          listItems = items
              .map(
                (entry) => ChatListItem(
                  title:
                      (entry as Map<String, dynamic>)['title'] as String? ?? '',
                  description:
                      entry['description'] as String? ??
                      entry['subtitle'] as String? ??
                      '',
                  reference: entry['reference'] as String?,
                ),
              )
              .where(
                (item) => item.title.isNotEmpty || item.description.isNotEmpty,
              )
              .toList();
          contentType = MessageContentType.list;
          if (messageText.isEmpty) {
            messageText = custom['title'] as String? ?? 'Contenido sugerido';
          }
        }
      }

      if (messageText.isEmpty && listItems.isNotEmpty) {
        messageText = 'Elementos encontrados';
      }

      final message = ChatMessageModel.fromRasa(
        id: _generateMessageId(prefix: 'bot'),
        conversationId: conversationId,
        contentType: contentType,
        text: messageText,
        timestamp: receivedAt,
        quickReplies: quickReplies,
        listItems: listItems,
        imageUrl: imageUrl,
        metadata: {
          if (custom != null) 'custom': custom,
          if (item.containsKey('recipient_id'))
            'recipient': item['recipient_id'],
        },
      );
      messages.add(message);
    }

    return messages;
  }

  String _generateMessageId({required String prefix}) {
    _messageCounter++;
    final millis = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$millis$_messageCounter';
  }
}
