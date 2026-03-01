import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/chat_message.dart';
import '../../../domain/usecases/chat/get_favorite_messages_usecase.dart';
import '../../../domain/usecases/chat/toggle_favorite_message_usecase.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  FavoritesBloc({
    required GetFavoriteMessagesUseCase getFavoriteMessagesUseCase,
    required ToggleFavoriteMessageUseCase toggleFavoriteMessageUseCase,
  }) : _getFavoriteMessagesUseCase = getFavoriteMessagesUseCase,
       _toggleFavoriteMessageUseCase = toggleFavoriteMessageUseCase,
       super(const FavoritesInitial()) {
    on<FavoritesStarted>(_onStarted);
    on<FavoriteRemoved>(_onRemoved);
  }

  final GetFavoriteMessagesUseCase _getFavoriteMessagesUseCase;
  final ToggleFavoriteMessageUseCase _toggleFavoriteMessageUseCase;

  Future<void> _onStarted(
    FavoritesStarted event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(const FavoritesLoading());
    try {
      final messages = await _getFavoriteMessagesUseCase.execute(
        conversationId: event.conversationId,
      );
      emit(FavoritesLoaded(favorites: messages));
    } catch (error) {
      emit(
        FavoritesError(
          'No se pudieron cargar los favoritos. ${error.toString()}',
        ),
      );
    }
  }

  Future<void> _onRemoved(
    FavoriteRemoved event,
    Emitter<FavoritesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FavoritesLoaded) {
      return;
    }

    emit(currentState.copyWith(isUpdating: true));

    try {
      await _toggleFavoriteMessageUseCase.execute(
        messageId: event.messageId,
        isFavorite: false,
      );

      final updatedList = currentState.favorites
          .where((message) => message.id != event.messageId)
          .toList(growable: false);

      emit(FavoritesLoaded(favorites: updatedList));
    } catch (error) {
      emit(
        FavoritesError(
          'No se pudo eliminar el favorito. ${error.toString()}',
        ),
      );
      emit(currentState.copyWith(isUpdating: false));
    }
  }
}

