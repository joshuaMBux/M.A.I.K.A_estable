import 'dart:convert';

import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.conversationId,
    required super.text,
    required super.type,
    required super.contentType,
    required super.status,
    required super.timestamp,
    super.senderId,
    super.imageUrl,
    super.listItems = const [],
    super.quickReplies = const [],
    super.generated = false,
    super.isFavorite = false,
    super.favoriteNote,
    super.metadata,
  });

  factory ChatMessageModel.fromDb(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      text: map['text'] as String,
      type: _parseMessageType(map['type'] as String?),
      contentType: _parseContentType(map['content_type'] as String?),
      status: _parseStatus(map['status'] as String?),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      senderId: map['sender'] as String?,
      imageUrl: map['image_url'] as String?,
      listItems: _decodeListItems(map['list_items'] as String?),
      quickReplies: _decodeQuickReplies(map['chips'] as String?),
      generated: (map['generated'] as int? ?? 0) == 1,
      isFavorite: (map['favorite_id'] as String?) != null,
      favoriteNote: map['favorite_note'] as String?,
      metadata: _decodeMetadata(map['metadata'] as String?),
    );
  }

  factory ChatMessageModel.fromRasa({
    required String id,
    required String conversationId,
    required MessageContentType contentType,
    required String text,
    required DateTime timestamp,
    List<ChatActionChip> quickReplies = const [],
    List<ChatListItem> listItems = const [],
    String? imageUrl,
    Map<String, dynamic>? metadata,
    bool generated = true,
  }) {
    return ChatMessageModel(
      id: id,
      conversationId: conversationId,
      text: text,
      type: MessageType.bot,
      contentType: contentType,
      status: MessageDeliveryStatus.delivered,
      timestamp: timestamp,
      imageUrl: imageUrl,
      quickReplies: quickReplies,
      listItems: listItems,
      metadata: metadata,
      generated: generated,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'text': text,
      'type': type.name,
      'status': status.name,
      'content_type': contentType.name,
      'created_at': timestamp.millisecondsSinceEpoch,
      'sender': senderId,
      'image_url': imageUrl,
      'list_items': _encodeListItems(listItems),
      'chips': _encodeQuickReplies(quickReplies),
      'metadata': _encodeMetadata(metadata),
      'generated': generated ? 1 : 0,
    };
  }

  ChatMessageModel copyWith({
    MessageDeliveryStatus? status,
    bool? isFavorite,
    String? favoriteNote,
  }) {
    return ChatMessageModel(
      id: id,
      conversationId: conversationId,
      text: text,
      type: type,
      contentType: contentType,
      status: status ?? this.status,
      timestamp: timestamp,
      senderId: senderId,
      imageUrl: imageUrl,
      listItems: listItems,
      quickReplies: quickReplies,
      generated: generated,
      isFavorite: isFavorite ?? this.isFavorite,
      favoriteNote: favoriteNote ?? this.favoriteNote,
      metadata: metadata,
    );
  }

  static MessageType _parseMessageType(String? raw) {
    return MessageType.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => MessageType.user,
    );
  }

  static MessageContentType _parseContentType(String? raw) {
    return MessageContentType.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => MessageContentType.text,
    );
  }

  static MessageDeliveryStatus _parseStatus(String? raw) {
    return MessageDeliveryStatus.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => MessageDeliveryStatus.pending,
    );
  }

  static List<ChatListItem> _decodeListItems(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      return decoded
          .map(
            (item) => ChatListItem(
              title: (item as Map<String, dynamic>)['title'] as String? ?? '',
              description:
                  item['description'] as String? ??
                  item['subtitle'] as String? ??
                  '',
              reference: item['reference'] as String?,
            ),
          )
          .where((item) => item.title.isNotEmpty || item.description.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static String _encodeListItems(List<ChatListItem> items) {
    if (items.isEmpty) {
      return '';
    }
    final encoded = items
        .map(
          (item) => {
            'title': item.title,
            'description': item.description,
            if (item.reference != null) 'reference': item.reference,
          },
        )
        .toList();
    return jsonEncode(encoded);
  }

  static List<ChatActionChip> _decodeQuickReplies(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      return decoded
          .map(
            (item) => ChatActionChip(
              title: (item as Map<String, dynamic>)['title'] as String? ?? '',
              payload: item['payload'] as String? ?? '',
            ),
          )
          .where((item) => item.title.isNotEmpty && item.payload.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static String _encodeQuickReplies(List<ChatActionChip> items) {
    if (items.isEmpty) {
      return '';
    }
    final encoded = items
        .map((item) => {'title': item.title, 'payload': item.payload})
        .toList();
    return jsonEncode(encoded);
  }

  static Map<String, dynamic>? _decodeMetadata(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) {
      return null;
    }
    try {
      return Map<String, dynamic>.from(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  static String? _encodeMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) {
      return null;
    }
    return jsonEncode(metadata);
  }
}
