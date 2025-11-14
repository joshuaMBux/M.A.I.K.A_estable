import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/usecases/chat/send_message_usecase.dart';

// Events
abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SendMessage extends ChatEvent {
  final String message;
  final String sender;

  SendMessage(this.message, this.sender);

  @override
  List<Object?> get props => [message, sender];
}

class LoadChatHistory extends ChatEvent {}

class ClearChat extends ChatEvent {}

// States
abstract class ChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;

  ChatLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatError extends ChatState {
  final String message;

  ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessageUseCase sendMessageUseCase;

  ChatBloc({required this.sendMessageUseCase}) : super(ChatInitial()) {
    on<SendMessage>(_onSendMessage);
    on<LoadChatHistory>(_onLoadChatHistory);
    on<ClearChat>(_onClearChat);
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      final messages = await sendMessageUseCase.execute(
        event.message,
        event.sender,
      );
      emit(ChatLoaded(messages));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onLoadChatHistory(
    LoadChatHistory event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      // Por ahora devolver mensaje de bienvenida
      final messages = [
        ChatMessage(
          id: 'welcome',
          message:
              '¡Hola! Soy Maika, tu asistente bíblico personal. ¿En qué puedo ayudarte hoy?',
          type: MessageType.bot,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ];
      emit(ChatLoaded(messages));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onClearChat(ClearChat event, Emitter<ChatState> emit) async {
    emit(ChatInitial());
  }
}
