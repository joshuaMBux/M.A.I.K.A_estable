import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MaikaLoadingAnimation extends StatefulWidget {
  const MaikaLoadingAnimation({
    super.key,
    this.width = 140,
  });

  final double width;

  @override
  State<MaikaLoadingAnimation> createState() => _MaikaLoadingAnimationState();
}

class _MaikaLoadingAnimationState extends State<MaikaLoadingAnimation> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/animations/loading.mp4',
    );
    _controller.setLooping(true);
    _initializeFuture = _controller.initialize().then((_) {
      if (mounted) {
        _controller.play();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: widget.width,
        child: FutureBuilder<void>(
          future: _initializeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done ||
                !_controller.value.isInitialized) {
              // Fallback mínimo mientras el video se prepara
              return const SizedBox(
                height: 48,
                width: 48,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }

            return AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: VideoPlayer(_controller),
              ),
            );
          },
        ),
      ),
    );
  }
}

