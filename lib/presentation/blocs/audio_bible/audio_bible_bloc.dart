import 'package:flutter_bloc/flutter_bloc.dart';
import 'audio_bible_event.dart';
import 'audio_bible_state.dart';
import '../../../data/repositories/audio_bible_repository.dart';
import '../../../core/services/audio_player_manager.dart';
import 'dart:async';

class AudioBibleBloc extends Bloc<AudioBibleEvent, AudioBibleState> {
  final AudioBibleRepository repository;
  final AudioPlayerManager playerManager;
  
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerStateSubscription;

  AudioBibleBloc({
    required this.repository,
    required this.playerManager,
  }) : super(const AudioBibleInitial()) {
    on<AudioBibleLoadBooks>(_onLoadBooks);
    on<AudioBibleLoadChapters>(_onLoadChapters);
    on<AudioBiblePlay>(_onPlay);
    on<AudioBibleDownload>(_onDownload);
    on<AudioBibleCancelDownload>(_onCancelDownload);
    on<AudioBibleDeleteDownload>(_onDeleteDownload);
    on<AudioBibleSyncMetadata>(_onSyncMetadata);
    
    _setupPlayerSubscriptions();
  }

  void _setupPlayerSubscriptions() {
    _playerStateSubscription = playerManager.playerStateStream.listen((playerState) {
      // Handle player state changes through events when needed
    });
  }

  Future<void> _onLoadBooks(
    AudioBibleLoadBooks event,
    Emitter<AudioBibleState> emit,
  ) async {
    emit(const AudioBibleLoading());
    try {
      final books = await repository.getLibros();
      emit(AudioBibleLoaded(books: books));
    } catch (error) {
      emit(AudioBibleError('Error al cargar libros: ${error.toString()}'));
    }
  }

  Future<void> _onLoadChapters(
    AudioBibleLoadChapters event,
    Emitter<AudioBibleState> emit,
  ) async {
    try {
      final chapters = await repository.getCapitulosConAudio(event.idLibro);
      if (state is AudioBibleLoaded) {
        final currentState = state as AudioBibleLoaded;
        emit(currentState.copyWith(chapters: chapters));
      }
    } catch (error) {
      emit(AudioBibleError('Error al cargar capítulos: ${error.toString()}'));
    }
  }

  Future<void> _onPlay(
    AudioBiblePlay event,
    Emitter<AudioBibleState> emit,
  ) async {
    try {
      final audio = await repository.getAudioParaCapitulo(event.idLibro, event.capitulo);
      if (audio == null) {
        emit(const AudioBibleError('Audio no disponible para este capítulo'));
        return;
      }

      final chapters = await repository.getCapitulosConAudio(event.idLibro);
      
      if (state is AudioBibleLoaded) {
        final currentState = state as AudioBibleLoaded;
        emit(currentState.copyWith(
          currentAudio: audio,
          chapters: chapters,
          isLoadingPlaylist: true,
        ));
      }

      // Load playlist if multiple chapters or single chapter
      await playerManager.loadPlaylist(chapters);
      
      if (state is AudioBibleLoaded) {
        final currentState = state as AudioBibleLoaded;
        emit(currentState.copyWith(isLoadingPlaylist: false));
      }

      // Start playback
      await playerManager.play();
      
    } catch (error) {
      emit(AudioBibleError('Error al reproducir audio: ${error.toString()}'));
      if (state is AudioBibleLoaded) {
        final currentState = state as AudioBibleLoaded;
        emit(currentState.copyWith(isLoadingPlaylist: false));
      }
    }
  }

  Future<void> _onDownload(
    AudioBibleDownload event,
    Emitter<AudioBibleState> emit,
  ) async {
    try {
      await repository.downloadAudio(event.audio);
      // Refresh chapters to show updated download status
      final chapters = await repository.getCapitulosConAudio(event.audio.idLibro);
      if (state is AudioBibleLoaded) {
        final currentState = state as AudioBibleLoaded;
        emit(currentState.copyWith(chapters: chapters));
      }
    } catch (error) {
      emit(AudioBibleError('Error al descargar audio: ${error.toString()}'));
    }
  }

  Future<void> _onCancelDownload(
    AudioBibleCancelDownload event,
    Emitter<AudioBibleState> emit,
  ) async {
    try {
      await repository.cancelDownload(event.audio);
      // Refresh chapters
      final chapters = await repository.getCapitulosConAudio(event.audio.idLibro);
      if (state is AudioBibleLoaded) {
        final currentState = state as AudioBibleLoaded;
        emit(currentState.copyWith(chapters: chapters));
      }
    } catch (error) {
      emit(AudioBibleError('Error al cancelar descarga: ${error.toString()}'));
    }
  }

  Future<void> _onDeleteDownload(
    AudioBibleDeleteDownload event,
    Emitter<AudioBibleState> emit,
  ) async {
    try {
      await repository.deleteDownloadedAudio(event.audio);
      // Refresh chapters
      final chapters = await repository.getCapitulosConAudio(event.audio.idLibro);
      if (state is AudioBibleLoaded) {
        final currentState = state as AudioBibleLoaded;
        emit(currentState.copyWith(chapters: chapters));
      }
    } catch (error) {
      emit(AudioBibleError('Error al eliminar audio: ${error.toString()}'));
    }
  }

  Future<void> _onSyncMetadata(
    AudioBibleSyncMetadata event,
    Emitter<AudioBibleState> emit,
  ) async {
    try {
      await repository.syncMetadata(version: event.version);
      // Reload books after sync
      add(const AudioBibleLoadBooks());
    } catch (error) {
      emit(AudioBibleError('Error al sincronizar metadatos: ${error.toString()}'));
    }
  }

  @override
  Future<void> close() async {
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    playerManager.dispose();
    return super.close();
  }
}

