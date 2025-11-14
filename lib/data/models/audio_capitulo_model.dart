enum AudioDownloadStatus {
  remote,
  downloading,
  complete,
  failed,
  outdated;

  String get dbValue {
    switch (this) {
      case AudioDownloadStatus.remote:
        return 'REMOTE';
      case AudioDownloadStatus.downloading:
        return 'DOWNLOADING';
      case AudioDownloadStatus.complete:
        return 'COMPLETE';
      case AudioDownloadStatus.failed:
        return 'FAILED';
      case AudioDownloadStatus.outdated:
        return 'OUTDATED';
    }
  }

  static AudioDownloadStatus fromDbValue(String? value) {
    switch (value) {
      case 'REMOTE':
        return AudioDownloadStatus.remote;
      case 'DOWNLOADING':
        return AudioDownloadStatus.downloading;
      case 'COMPLETE':
        return AudioDownloadStatus.complete;
      case 'FAILED':
        return AudioDownloadStatus.failed;
      case 'OUTDATED':
        return AudioDownloadStatus.outdated;
      default:
        return AudioDownloadStatus.remote;
    }
  }
}

class AudioCapitulo {
  final int? idAudio;
  final int idLibro;
  final int capitulo;
  final String? url;
  final int? duracionSegundos;
  final String? localPath;
  final AudioDownloadStatus downloadStatus;
  final int? fileSizeBytes;
  final String? checksumHash;

  AudioCapitulo({
    this.idAudio,
    required this.idLibro,
    required this.capitulo,
    this.url,
    this.duracionSegundos,
    this.localPath,
    this.downloadStatus = AudioDownloadStatus.remote,
    this.fileSizeBytes,
    this.checksumHash,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_audio': idAudio,
      'id_libro': idLibro,
      'capitulo': capitulo,
      'url': url,
      'duracion_segundos': duracionSegundos,
      'local_path': localPath,
      'download_status': downloadStatus.dbValue,
      'file_size_bytes': fileSizeBytes,
      'checksum_hash': checksumHash,
    };
  }

  factory AudioCapitulo.fromMap(Map<String, dynamic> map) {
    return AudioCapitulo(
      idAudio: map['id_audio'] as int?,
      idLibro: map['id_libro'] as int,
      capitulo: map['capitulo'] as int,
      url: map['url'] as String?,
      duracionSegundos: map['duracion_segundos'] as int?,
      localPath: map['local_path'] as String?,
      downloadStatus: AudioDownloadStatus.fromDbValue(map['download_status'] as String?),
      fileSizeBytes: map['file_size_bytes'] as int?,
      checksumHash: map['checksum_hash'] as String?,
    );
  }

  AudioCapitulo copyWith({
    int? idAudio,
    int? idLibro,
    int? capitulo,
    String? url,
    int? duracionSegundos,
    String? localPath,
    AudioDownloadStatus? downloadStatus,
    int? fileSizeBytes,
    String? checksumHash,
  }) {
    return AudioCapitulo(
      idAudio: idAudio ?? this.idAudio,
      idLibro: idLibro ?? this.idLibro,
      capitulo: capitulo ?? this.capitulo,
      url: url ?? this.url,
      duracionSegundos: duracionSegundos ?? this.duracionSegundos,
      localPath: localPath ?? this.localPath,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      checksumHash: checksumHash ?? this.checksumHash,
    );
  }
}


