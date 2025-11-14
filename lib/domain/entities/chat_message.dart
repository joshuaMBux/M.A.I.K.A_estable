import 'package:equatable/equatable.dart';

enum MessageType { user, bot }

class ChatMessage extends Equatable {
  final String id;
  final String message;
  final MessageType type;
  final DateTime timestamp;
  final String? senderId;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.message,
    required this.type,
    required this.timestamp,
    this.senderId,
    this.metadata,
  });

  @override
  List<Object?> get props => [id, message, type, timestamp, senderId, metadata];
}
