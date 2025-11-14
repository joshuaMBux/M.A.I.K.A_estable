import 'package:equatable/equatable.dart';
import '../../../data/models/audio_capitulo_model.dart';

abstract class AudioBibleEvent extends Equatable {
  const AudioBibleEvent();

  @override
  List<Object?> get props => [];
}

class AudioBibleLoadBooks extends AudioBibleEvent {
  const AudioBibleLoadBooks();
}

class AudioBibleLoadChapters extends AudioBibleEvent {
  final int idLibro;

  const AudioBibleLoadChapters(this.idLibro);

  @override
  List<Object?> get props => [idLibro];
}

class AudioBiblePlay extends AudioBibleEvent {
  final int idLibro;
  final int capitulo;

  const AudioBiblePlay({
    required this.idLibro,
    required this.capitulo,
  });

  @override
  List<Object?> get props => [idLibro, capitulo];
}

class AudioBibleDownload extends AudioBibleEvent {
  final AudioCapitulo audio;

  const AudioBibleDownload(this.audio);

  @override
  List<Object?> get props => [audio];
}

class AudioBibleCancelDownload extends AudioBibleEvent {
  final AudioCapitulo audio;

  const AudioBibleCancelDownload(this.audio);

  @override
  List<Object?> get props => [audio];
}

class AudioBibleDeleteDownload extends AudioBibleEvent {
  final AudioCapitulo audio;

  const AudioBibleDeleteDownload(this.audio);

  @override
  List<Object?> get props => [audio];
}

class AudioBibleSyncMetadata extends AudioBibleEvent {
  final String version;

  const AudioBibleSyncMetadata({this.version = 'rv1960'});

  @override
  List<Object?> get props => [version];
}

