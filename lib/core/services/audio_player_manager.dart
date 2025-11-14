import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/audio_capitulo_model.dart';

/// Manager for audio playback with gapless playback support and offline-first strategy
class AudioPlayerManager {
  final AudioPlayer _player = AudioPlayer();
  
  final StreamController<Duration> _positionStreamController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationStreamController = StreamController<Duration>.broadcast();
  final StreamController<PlayerState> _playerStateStreamController = StreamController<PlayerState>.broadcast();
  final StreamController<int?> _currentIndexStreamController = StreamController<int?>.broadcast();

  Stream<Duration> get positionStream => _positionStreamController.stream;
  Stream<Duration> get durationStream => _durationStreamController.stream;
  Stream<PlayerState> get playerStateStream => _playerStateStreamController.stream;
  Stream<int?> get currentIndexStream => _currentIndexStreamController.stream;

  AudioPlayerManager() {
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    _player.positionStream.listen((position) {
      _positionStreamController.add(position);
    });

    _player.durationStream.listen((duration) {
      if (duration != null) {
        _durationStreamController.add(duration);
      }
    });

    _player.playerStateStream.listen((state) {
      _playerStateStreamController.add(state);
    });

    _player.currentIndexStream.listen((index) {
      _currentIndexStreamController.add(index);
    });
  }

  /// Build an AudioSource for a single chapter (offline-first strategy)
  Future<AudioSource> _buildAudioSource(AudioCapitulo audio) async {
    // Web: handle assets and URLs properly
    if (kIsWeb) {
      // Priority 1: Remote URL if available
      if (audio.url != null && audio.url!.isNotEmpty) {
        return AudioSource.uri(Uri.parse(audio.url!));
      }
      // Priority 2: Asset file (bundled in app)
      if (audio.localPath != null && audio.localPath!.isNotEmpty) {
        // Check if it's an asset path (starts with 'assets/')
        if (audio.localPath!.startsWith('assets/')) {
          // Use AudioSource.asset() for bundled assets in web
          return AudioSource.asset(audio.localPath!);
        }
        // If it's a full URL path, use it directly
        return AudioSource.uri(Uri.parse(audio.localPath!));
      }
      throw Exception('No valid audio source for ${audio.idLibro}:${audio.capitulo}');
    }

    // Mobile/desktop: offline-first strategy
    // Priority 1: Use local file if downloaded and complete
    if (audio.downloadStatus == AudioDownloadStatus.complete &&
        audio.localPath != null &&
        audio.localPath!.isNotEmpty) {
      // Check if it's an asset path (for assets bundled in app)
      if (audio.localPath!.startsWith('assets/')) {
        return AudioSource.asset(audio.localPath!);
      }
      // Otherwise, treat as file path
      try {
        final localFile = Uri.file(audio.localPath!);
        return AudioSource.uri(localFile);
      } catch (e) {
        debugPrint('Error loading local file for ${audio.idLibro}:${audio.capitulo}: $e');
        // Fall through to try remote URL if local fails
      }
    }

    // Priority 2: Use remote URL if available (for streaming)
    // This works even if downloadStatus is 'remote' or 'downloading'
    if (audio.url != null && audio.url!.isNotEmpty) {
      try {
        return AudioSource.uri(Uri.parse(audio.url!));
      } catch (e) {
        debugPrint('Error parsing remote URL for ${audio.idLibro}:${audio.capitulo}: $e');
      }
    }

    // Priority 3: Try asset fallback if localPath is set but status is not complete
    if (audio.localPath != null && audio.localPath!.isNotEmpty && audio.localPath!.startsWith('assets/')) {
      return AudioSource.asset(audio.localPath!);
    }

    throw Exception('No valid audio source for ${audio.idLibro}:${audio.capitulo}');
  }

  /// Load a single audio chapter
  Future<void> loadAudio(AudioCapitulo audio) async {
    try {
      final source = await _buildAudioSource(audio);
      await _player.setAudioSource(source);
    } catch (e) {
      debugPrint('Error loading audio: $e');
      rethrow;
    }
  }

  /// Load multiple chapters for gapless playback (lazy loading enabled)
  Future<void> loadPlaylist(List<AudioCapitulo> audioList) async {
    if (audioList.isEmpty) {
      throw Exception('Empty playlist');
    }

    try {
      final sources = <AudioSource>[];
      
      for (final audio in audioList) {
        final source = await _buildAudioSource(audio);
        sources.add(source);
      }

      final playlist = ConcatenatingAudioSource(
        children: sources,
        useLazyPreparation: true, // Enable lazy loading for performance
      );

      await _player.setAudioSource(playlist);
    } catch (e) {
      debugPrint('Error loading playlist: $e');
      rethrow;
    }
  }

  /// Play the current audio
  Future<void> play() async {
    await _player.play();
  }

  /// Pause the current audio
  Future<void> pause() async {
    await _player.pause();
  }

  /// Stop playback
  Future<void> stop() async {
    await _player.stop();
  }

  /// Seek to a specific position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Seek to a specific chapter in playlist
  Future<void> seekToChapter(int index) async {
    await _player.seek(Duration.zero, index: index);
  }

  /// Skip forward by a duration
  Future<void> skipForward(Duration duration) async {
    final currentPosition = await _player.position;
    final seekPosition = currentPosition + duration;
    final totalDuration = await _player.duration;
    
    if (totalDuration != null && seekPosition > totalDuration) {
      // Skip to next track if available
      final nextIndex = _player.currentIndex;
      if (nextIndex != null && nextIndex < (_player.sequence?.length ?? 0) - 1) {
        await seekToChapter(nextIndex + 1);
      } else {
        await stop();
      }
    } else {
      await seek(seekPosition);
    }
  }

  /// Skip backward by a duration
  Future<void> skipBackward(Duration duration) async {
    final currentPosition = await _player.position;
    final seekPosition = currentPosition - duration;
    
    if (seekPosition < Duration.zero) {
      // Skip to previous track if available
      final currentIndex = _player.currentIndex;
      if (currentIndex != null && currentIndex > 0) {
        await seekToChapter(currentIndex - 1);
      } else {
        await seek(Duration.zero);
      }
    } else {
      await seek(seekPosition);
    }
  }

  /// Get current playback position
  Future<Duration> getPosition() async => await _player.position;

  /// Get total duration
  Future<Duration?> getDuration() async => await _player.duration;

  /// Get current player state
  Future<PlayerState> getPlayerState() => Future.value(_player.playerState);

  /// Get current index in playlist (null if single track)
  Future<int?> getCurrentIndex() => Future.value(_player.currentIndex);

  /// Check if playing
  Future<bool> isPlaying() async {
    final state = await getPlayerState();
    return state.playing && state.processingState == ProcessingState.ready;
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Get volume
  Future<double> getVolume() => Future.value(_player.volume);

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed.clamp(0.25, 2.0));
  }

  /// Get playback speed
  Future<double> getSpeed() => Future.value(_player.speed);

  /// Dispose resources
  void dispose() async {
    await _player.dispose();
    await _positionStreamController.close();
    await _durationStreamController.close();
    await _playerStateStreamController.close();
    await _currentIndexStreamController.close();
  }
}

