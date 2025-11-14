import 'package:equatable/equatable.dart';

enum MessageType { user, bot }

enum MessageContentType { text, image, list }

enum MessageDeliveryStatus { pending, sent, delivered, error }

class ChatActionChip extends Equatable {
  final String title;
  final String payload;

  const ChatActionChip({required this.title, required this.payload});

  @override
  List<Object?> get props => [title, payload];
}

class ChatListItem extends Equatable {
  final String title;
  final String description;
  final String? reference;

  const ChatListItem({
    required this.title,
    required this.description,
    this.reference,
  });

  @override
  List<Object?> get props => [title, description, reference];
}

class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String text;
  final MessageType type;
  final MessageContentType contentType;
  final MessageDeliveryStatus status;
  final DateTime timestamp;
  final String? senderId;
  final String? imageUrl;
  final List<ChatListItem> listItems;
  final List<ChatActionChip> quickReplies;
  final bool generated;
  final bool isFavorite;
  final String? favoriteNote;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.type,
    required this.contentType,
    required this.status,
    required this.timestamp,
    this.senderId,
    this.imageUrl,
    this.listItems = const [],
    this.quickReplies = const [],
    this.generated = false,
    this.isFavorite = false,
    this.favoriteNote,
    this.metadata,
  });

  bool get isPending => status == MessageDeliveryStatus.pending;

  bool get isError => status == MessageDeliveryStatus.error;

  @override
  List<Object?> get props => [
    id,
    conversationId,
    text,
    type,
    contentType,
    status,
    timestamp,
    senderId,
    imageUrl,
    listItems,
    quickReplies,
    generated,
    isFavorite,
    favoriteNote,
    metadata,
  ];
}
