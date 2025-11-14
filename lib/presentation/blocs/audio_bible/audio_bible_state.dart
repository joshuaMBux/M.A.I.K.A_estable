import 'package:equatable/equatable.dart';
import '../../../data/models/audio_capitulo_model.dart';
import '../../../data/models/libro_model.dart';

abstract class AudioBibleState extends Equatable {
  const AudioBibleState();

  @override
  List<Object?> get props => [];
}

class AudioBibleInitial extends AudioBibleState {
  const AudioBibleInitial();
}

class AudioBibleLoading extends AudioBibleState {
  const AudioBibleLoading();
}

class AudioBibleLoaded extends AudioBibleState {
  final List<Libro> books;
  final List<AudioCapitulo>? chapters;
  final AudioCapitulo? currentAudio;
  final bool isPlaying;
  final bool isLoadingPlaylist;

  const AudioBibleLoaded({
    required this.books,
    this.chapters,
    this.currentAudio,
    this.isPlaying = false,
    this.isLoadingPlaylist = false,
  });

  AudioBibleLoaded copyWith({
    List<Libro>? books,
    List<AudioCapitulo>? chapters,
    AudioCapitulo? currentAudio,
    bool? isPlaying,
    bool? isLoadingPlaylist,
  }) {
    return AudioBibleLoaded(
      books: books ?? this.books,
      chapters: chapters ?? this.chapters,
      currentAudio: currentAudio ?? this.currentAudio,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoadingPlaylist: isLoadingPlaylist ?? this.isLoadingPlaylist,
    );
  }

  @override
  List<Object?> get props => [books, chapters, currentAudio, isPlaying, isLoadingPlaylist];
}

class AudioBibleError extends AudioBibleState {
  final String message;

  const AudioBibleError(this.message);

  @override
  List<Object?> get props => [message];
}

