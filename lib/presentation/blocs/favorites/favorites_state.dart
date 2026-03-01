import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_message.dart';

abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {
  const FavoritesInitial();
}

class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

class FavoritesLoaded extends FavoritesState {
  final List<ChatMessage> favorites;
  final bool isUpdating;

  const FavoritesLoaded({
    required this.favorites,
    this.isUpdating = false,
  });

  FavoritesLoaded copyWith({
    List<ChatMessage>? favorites,
    bool? isUpdating,
  }) {
    return FavoritesLoaded(
      favorites: favorites ?? this.favorites,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object?> get props => [favorites, isUpdating];
}

class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError(this.message);

  @override
  List<Object?> get props => [message];
}

