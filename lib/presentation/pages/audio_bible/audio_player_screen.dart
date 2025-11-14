import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../blocs/audio_bible/audio_bible_bloc.dart';
import '../../blocs/audio_bible/audio_bible_state.dart';
import '../../../data/models/audio_capitulo_model.dart';
import '../../../data/repositories/audio_bible_repository.dart';
import '../../../core/services/audio_player_manager.dart';
import '../../../core/utils/download_helper.dart';
import '../../../core/config/download_config.dart';
import 'dart:async';

class AudioPlayerScreen extends StatefulWidget {
  final int idLibro;
  final int capitulo;
  final String bookName;

  const AudioPlayerScreen({
    super.key,
    required this.bookName,
    required this.idLibro,
    required this.capitulo,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayerManager _playerManager;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    // Get player manager from DI
    _playerManager = di.sl<AudioPlayerManager>();
    _setupPlayerSubscriptions();

    // Get audio repository to load and play
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAndPlayAudio();
    });
  }

  Future<void> _loadAndPlayAudio() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final repository = di.sl<AudioBibleRepository>();
      final audio = await repository.getAudioParaCapitulo(
        widget.idLibro,
        widget.capitulo,
      );
      
      if (audio == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se encontró audio para este capítulo';
        });
        return;
      }

      if (!mounted) return;

      final chapters = await repository.getCapitulosConAudio(widget.idLibro);
      
      if (chapters.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No hay capítulos disponibles para este libro';
        });
        return;
      }

      // Find the index of the current chapter in the playlist
      final currentIndex = chapters.indexWhere((ch) => ch.capitulo == widget.capitulo);
      
      await _playerManager.loadPlaylist(chapters);
      
      // Seek to the correct chapter if not at index 0
      if (currentIndex > 0) {
        await _playerManager.seekToChapter(currentIndex);
      }
      
      // Wait a bit for the player to be ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      await _playerManager.play();
      
      // Update duration after loading
      final duration = await _playerManager.getDuration();
      if (duration != null && mounted) {
        setState(() {
          _duration = duration;
          _isPlaying = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isPlaying = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading audio: $e');
      debugPrint('Attempted to load audio for book ${widget.idLibro}, chapter ${widget.capitulo}');
      if (mounted) {
        // Get the audio URL for debugging
        final repository = di.sl<AudioBibleRepository>();
        final audioUrl = await repository.getAudioParaCapitulo(widget.idLibro, widget.capitulo);
        debugPrint('Audio URL: ${audioUrl?.url}');
        debugPrint('Audio localPath: ${audioUrl?.localPath}');
        
        setState(() {
          _isLoading = false;
          final errorMsg = e.toString();
          // Provide more helpful error message
          if (errorMsg.contains('SOURCE ERROR') || errorMsg.contains('0')) {
            _errorMessage = 'Error al cargar el audio. Verifica tu conexión a Internet.\n\nURL: ${audioUrl?.url ?? "No disponible"}';
          } else {
            _errorMessage = 'Error al cargar el audio: $errorMsg';
          }
        });
      }
    }
  }

  void _setupPlayerSubscriptions() {
    _posSub = _playerManager.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });

    _durSub = _playerManager.durationStream.listen((dur) {
      if (!mounted) return;
      setState(() => _duration = dur);
    });

    _stateSub = _playerManager.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        // Ensure controls show as soon as the player is ready/buffering on web
        if (_isLoading &&
            (state.processingState == ProcessingState.ready ||
                state.processingState == ProcessingState.buffering)) {
          _isLoading = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    // Stop playback to avoid continuing in background when leaving the page
    _playerManager.stop();
    super.dispose();
  }

  Future<void> _handlePlayPause() async {
    final isPlaying = await _playerManager.isPlaying();
    if (isPlaying) {
      await _playerManager.pause();
    } else {
      await _playerManager.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  Future<void> _skipForward() async {
    await _playerManager.skipForward(const Duration(seconds: 10));
  }

  Future<void> _skipBackward() async {
    await _playerManager.skipBackward(const Duration(seconds: 10));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textPrimary = scheme.textPrimary;
    final textSecondary = scheme.textSecondary;

    return BlocProvider.value(
      value: di.sl<AudioBibleBloc>(),
      child: WillPopScope(
        onWillPop: () async {
          // Ensure playback stops when leaving the page
          try {
            await _playerManager.stop();
          } catch (_) {}
          return true;
        },
        child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.bookName} ${widget.capitulo}'),
          actions: [
            IconButton(
              tooltip: 'Descargar',
              icon: const Icon(Icons.download),
              onPressed: () async {
                // In web without proxy, disable download to avoid navigation/autoplay issues
                if (kIsWeb && (audioProxyBaseUrl == null || audioProxyBaseUrl!.isEmpty)) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Descarga no disponible en web (CORS).'),
                      ),
                    );
                  }
                  return;
                }

                final repository = di.sl<AudioBibleRepository>();
                final audio = await repository.getAudioParaCapitulo(
                  widget.idLibro,
                  widget.capitulo,
                );
                if (audio == null) return;
                if (audio.url == null || audio.url!.isEmpty) return;
                try {
                  // Pause playback to avoid audio continuing if browser opens a new tab
                  try { await _playerManager.pause(); } catch (_) {}
                  final filename = '${widget.bookName}_${widget.capitulo}.mp3';
                  await pickAndSaveAudioFromUrl(
                    audio.url!,
                    filename: filename,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Descarga iniciada')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al descargar: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
        body: BlocBuilder<AudioBibleBloc, AudioBibleState>(
          builder: (context, state) {
            String sourceInfo = 'Preparando...';

            if (state is AudioBibleLoaded && state.currentAudio != null) {
              final audio = state.currentAudio!;
              if (audio.downloadStatus == AudioDownloadStatus.complete &&
                  audio.localPath != null &&
                  !audio.localPath!.startsWith('assets/')) {
                sourceInfo = 'Reproduciendo archivo local';
              } else {
                sourceInfo = 'Reproduciendo desde internet';
              }
            }

            if (_isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (_errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: scheme.error),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadAndPlayAudio,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  Icon(Icons.library_music, size: 96, color: scheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    'Capítulo ${widget.capitulo}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(sourceInfo, style: TextStyle(color: textSecondary)),
                  const Spacer(),
                  Slider(
                    value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                    max: (_duration.inSeconds == 0
                        ? 1.0
                        : _duration.inSeconds.toDouble()),
                    onChanged: (v) async {
                      await _playerManager.seek(Duration(seconds: v.toInt()));
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _format(_position),
                        style: TextStyle(color: textSecondary),
                      ),
                      Text(
                        _format(_duration),
                        style: TextStyle(color: textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 36,
                        onPressed: _skipBackward,
                        icon: const Icon(Icons.replay_10),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _handlePlayPause,
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        iconSize: 36,
                        onPressed: _skipForward,
                        icon: const Icon(Icons.forward_10),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            );
          },
        ),
        ),
      ),
    );
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }
}
