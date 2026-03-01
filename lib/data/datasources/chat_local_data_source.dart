import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import '../../domain/entities/chat_message.dart';
import '../models/chat_message_model.dart';

abstract class ChatLocalDataSource {
  Future<String> ensureConversation(String? conversationId);
  Future<void> updateConversationTimestamp(String conversationId);
  Future<void> insertMessage(ChatMessageModel message);
  Future<void> insertMessages(List<ChatMessageModel> messages);
  Future<List<ChatMessageModel>> getMessages(String conversationId);
  Future<List<ChatMessageModel>> getPendingMessages(String conversationId);
  Future<List<ChatMessageModel>> getFavoriteMessages({String? conversationId});
  Future<void> updateMessageStatus(
    String messageId,
    MessageDeliveryStatus status,
  );
  Future<void> markFavorite({
    required String messageId,
    required bool isFavorite,
    String? note,
  });
  List<ChatActionChip> defaultSuggestions();
}

class SqliteChatLocalDataSource implements ChatLocalDataSource {
  SqliteChatLocalDataSource(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  Future<Database> get _db async => _databaseHelper.database;

  @override
  Future<String> ensureConversation(String? conversationId) async {
    final db = await _db;
    final id = conversationId ?? _generateConversationId();
    await db.insert('conversations', {
      'id': id,
      'title': 'Conversacion ${DateTime.now().millisecondsSinceEpoch}',
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    return id;
  }

  @override
  Future<void> updateConversationTimestamp(String conversationId) async {
    final db = await _db;
    await db.update(
      'conversations',
      {'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  @override
  Future<void> insertMessage(ChatMessageModel message) async {
    final db = await _db;
    await db.insert(
      'messages',
      message.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await updateConversationTimestamp(message.conversationId);
  }

  @override
  Future<void> insertMessages(List<ChatMessageModel> messages) async {
    if (messages.isEmpty) {
      return;
    }
    final db = await _db;
    await db.transaction((txn) async {
      for (final message in messages) {
        await txn.insert(
          'messages',
          message.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await txn.update(
          'conversations',
          {'updated_at': DateTime.now().millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [message.conversationId],
        );
      }
    });
  }

  @override
  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT m.*, f.id AS favorite_id, f.note AS favorite_note
      FROM messages m
      LEFT JOIN favorites f ON m.id = f.message_id
      WHERE m.conversation_id = ?
      ORDER BY m.created_at ASC
      ''',
      [conversationId],
    );
    return rows.map(ChatMessageModel.fromDb).toList();
  }

  @override
  Future<List<ChatMessageModel>> getPendingMessages(
    String conversationId,
  ) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT m.*, f.id AS favorite_id, f.note AS favorite_note
      FROM messages m
      LEFT JOIN favorites f ON m.id = f.message_id
      WHERE m.conversation_id = ? AND (m.status = ? OR m.status = ?)
      ORDER BY m.created_at ASC
      ''',
      [
        conversationId,
        MessageDeliveryStatus.pending.name,
        MessageDeliveryStatus.error.name,
      ],
    );
    return rows.map(ChatMessageModel.fromDb).toList();
  }

  @override
  Future<List<ChatMessageModel>> getFavoriteMessages({
    String? conversationId,
  }) async {
    final db = await _db;
    final hasConversationFilter =
        conversationId != null && conversationId.isNotEmpty;
    final whereClause =
        hasConversationFilter ? 'WHERE m.conversation_id = ?' : '';
    final whereArgs = hasConversationFilter ? [conversationId] : <Object>[];

    final rows = await db.rawQuery(
      '''
      SELECT m.*, f.id AS favorite_id, f.note AS favorite_note
      FROM favorites f
      JOIN messages m ON m.id = f.message_id
      $whereClause
      ORDER BY f.created_at DESC
      ''',
      whereArgs,
    );
    return rows.map(ChatMessageModel.fromDb).toList();
  }

  @override
  Future<void> updateMessageStatus(
    String messageId,
    MessageDeliveryStatus status,
  ) async {
    final db = await _db;
    await db.update(
      'messages',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  @override
  Future<void> markFavorite({
    required String messageId,
    required bool isFavorite,
    String? note,
  }) async {
    final db = await _db;
    if (isFavorite) {
      await db.insert('favorites', {
        'id': '${messageId}_fav',
        'message_id': messageId,
        'note': note,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete(
        'favorites',
        where: 'message_id = ?',
        whereArgs: [messageId],
      );
    }
  }

  @override
  List<ChatActionChip> defaultSuggestions() {
    return const [
      ChatActionChip(title: 'Versiculo del dia', payload: '/verse_of_the_day'),
      ChatActionChip(
        title: 'Contexto historico',
        payload: '/historical_context',
      ),
      ChatActionChip(title: 'Guardados', payload: '/show_favorites'),
      ChatActionChip(title: 'Recomendaciones', payload: '/reading_suggestions'),
    ];
  }

  String _generateConversationId() {
    return 'conv_${DateTime.now().millisecondsSinceEpoch}';
  }
}

class InMemoryChatLocalDataSource implements ChatLocalDataSource {
  final Map<String, List<ChatMessageModel>> _messagesByConversation = {};
  final Map<String, ChatMessageModel> _messagesById = {};
  final Map<String, DateTime> _conversationUpdated = {};

  @override
  Future<String> ensureConversation(String? conversationId) async {
    final id = conversationId ?? _generateConversationId();
    _messagesByConversation.putIfAbsent(id, () => <ChatMessageModel>[]);
    _conversationUpdated[id] = DateTime.now();
    return id;
  }

  @override
  Future<void> updateConversationTimestamp(String conversationId) async {
    _conversationUpdated[conversationId] = DateTime.now();
  }

  @override
  Future<void> insertMessage(ChatMessageModel message) async {
    final conversation = _messagesByConversation.putIfAbsent(
      message.conversationId,
      () => [],
    );
    conversation.add(message);
    _messagesById[message.id] = message;
    conversation.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _conversationUpdated[message.conversationId] = DateTime.now();
  }

  @override
  Future<void> insertMessages(List<ChatMessageModel> messages) async {
    if (messages.isEmpty) return;
    for (final message in messages) {
      await insertMessage(message);
    }
  }

  @override
  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    final messages =
        _messagesByConversation[conversationId] ?? <ChatMessageModel>[];
    return List<ChatMessageModel>.unmodifiable(messages);
  }

  @override
  Future<List<ChatMessageModel>> getPendingMessages(
    String conversationId,
  ) async {
    final messages =
        _messagesByConversation[conversationId] ?? <ChatMessageModel>[];
    return messages
        .where(
          (message) =>
              message.status == MessageDeliveryStatus.pending ||
              message.status == MessageDeliveryStatus.error,
        )
        .toList(growable: false);
  }

  @override
  Future<List<ChatMessageModel>> getFavoriteMessages({
    String? conversationId,
  }) async {
    final Iterable<ChatMessageModel> allMessages =
        _messagesByConversation.values.expand((messages) => messages);
    final filtered = allMessages.where((message) {
      final matchesConversation =
          conversationId == null ||
          conversationId.isEmpty ||
          message.conversationId == conversationId;
      return matchesConversation && message.isFavorite;
    }).toList(growable: false);
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  @override
  Future<void> updateMessageStatus(
    String messageId,
    MessageDeliveryStatus status,
  ) async {
    final message = _messagesById[messageId];
    if (message == null) return;
    final updated = message.copyWith(status: status);
    _messagesById[messageId] = updated;

    final conversation = _messagesByConversation[message.conversationId];
    if (conversation == null) return;
    final index = conversation.indexWhere((item) => item.id == messageId);
    if (index != -1) {
      conversation[index] = updated;
    }
  }

  @override
  Future<void> markFavorite({
    required String messageId,
    required bool isFavorite,
    String? note,
  }) async {
    final message = _messagesById[messageId];
    if (message == null) return;
    final updated = message.copyWith(
      isFavorite: isFavorite,
      favoriteNote: isFavorite ? note : null,
    );
    _messagesById[messageId] = updated;

    final conversation = _messagesByConversation[message.conversationId];
    if (conversation == null) return;
    final index = conversation.indexWhere((item) => item.id == messageId);
    if (index != -1) {
      conversation[index] = updated;
    }
  }

  @override
  List<ChatActionChip> defaultSuggestions() {
    return const [
      ChatActionChip(title: 'Versiculo del dia', payload: '/verse_of_the_day'),
      ChatActionChip(
        title: 'Contexto historico',
        payload: '/historical_context',
      ),
      ChatActionChip(title: 'Guardados', payload: '/show_favorites'),
      ChatActionChip(title: 'Recomendaciones', payload: '/reading_suggestions'),
    ];
  }

  String _generateConversationId() {
    return 'conv_${DateTime.now().millisecondsSinceEpoch}_${_messagesByConversation.length + 1}';
  }
}

ChatLocalDataSource createChatLocalDataSource(DatabaseHelper? databaseHelper) {
  if (!kIsWeb && databaseHelper != null) {
    return SqliteChatLocalDataSource(databaseHelper);
  }
  return InMemoryChatLocalDataSource();
}
