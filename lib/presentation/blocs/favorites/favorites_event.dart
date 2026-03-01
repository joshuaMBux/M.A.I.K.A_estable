import 'package:equatable/equatable.dart';

class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

class FavoritesStarted extends FavoritesEvent {
  const FavoritesStarted({this.conversationId});

  final String? conversationId;

  @override
  List<Object?> get props => [conversationId];
}

class FavoriteRemoved extends FavoritesEvent {
  const FavoriteRemoved(this.messageId);

  final String messageId;

  @override
  List<Object?> get props => [messageId];
}

