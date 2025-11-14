import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../models/audio_capitulo_model.dart';
import '../models/libro_model.dart';
import '../../core/services/audio_sync_service.dart';
import '../../core/services/audio_download_service.dart';

class AudioBibleRepository {
  final DatabaseHelper? _dbHelper = kIsWeb ? null : DatabaseHelper();
  AudioSyncService? _syncService;
  AudioDownloadService? _downloadService;

  AudioBibleRepository({
    DatabaseHelper? dbHelper,
    AudioSyncService? syncService,
    AudioDownloadService? downloadService,
  }) : _syncService = syncService,
       _downloadService = downloadService {
    if (!kIsWeb) {
      final helper = dbHelper ?? DatabaseHelper();
      _syncService ??= AudioSyncService(helper);
      _downloadService ??= AudioDownloadService(helper);
    }
  }

  Future<List<Libro>> getLibros() async {
    if (kIsWeb) {
      // Return all 66 books of the Bible for web
      return _getAllBibleBooks();
    }
    final db = await _dbHelper!.database;
    final maps = await db.query('libro', orderBy: 'orden ASC');
    return maps.map((m) => Libro.fromMap(m)).toList();
  }

  /// Generate list of all 66 books of the Bible
  List<Libro> _getAllBibleBooks() {
    return [
      // Old Testament (39 books)
      Libro(idLibro: 1, nombre: 'Génesis', abreviatura: 'Gn', orden: 1),
      Libro(idLibro: 2, nombre: 'Éxodo', abreviatura: 'Ex', orden: 2),
      Libro(idLibro: 3, nombre: 'Levítico', abreviatura: 'Lv', orden: 3),
      Libro(idLibro: 4, nombre: 'Números', abreviatura: 'Nm', orden: 4),
      Libro(idLibro: 5, nombre: 'Deuteronomio', abreviatura: 'Dt', orden: 5),
      Libro(idLibro: 6, nombre: 'Josué', abreviatura: 'Jos', orden: 6),
      Libro(idLibro: 7, nombre: 'Jueces', abreviatura: 'Jue', orden: 7),
      Libro(idLibro: 8, nombre: 'Rut', abreviatura: 'Rt', orden: 8),
      Libro(idLibro: 9, nombre: '1 Samuel', abreviatura: '1S', orden: 9),
      Libro(idLibro: 10, nombre: '2 Samuel', abreviatura: '2S', orden: 10),
      Libro(idLibro: 11, nombre: '1 Reyes', abreviatura: '1R', orden: 11),
      Libro(idLibro: 12, nombre: '2 Reyes', abreviatura: '2R', orden: 12),
      Libro(idLibro: 13, nombre: '1 Crónicas', abreviatura: '1Cr', orden: 13),
      Libro(idLibro: 14, nombre: '2 Crónicas', abreviatura: '2Cr', orden: 14),
      Libro(idLibro: 15, nombre: 'Esdras', abreviatura: 'Esd', orden: 15),
      Libro(idLibro: 16, nombre: 'Nehemías', abreviatura: 'Neh', orden: 16),
      Libro(idLibro: 17, nombre: 'Ester', abreviatura: 'Est', orden: 17),
      Libro(idLibro: 18, nombre: 'Job', abreviatura: 'Job', orden: 18),
      Libro(idLibro: 19, nombre: 'Salmos', abreviatura: 'Sal', orden: 19),
      Libro(idLibro: 20, nombre: 'Proverbios', abreviatura: 'Pr', orden: 20),
      Libro(idLibro: 21, nombre: 'Eclesiastés', abreviatura: 'Ec', orden: 21),
      Libro(idLibro: 22, nombre: 'Cantares', abreviatura: 'Cnt', orden: 22),
      Libro(idLibro: 23, nombre: 'Isaías', abreviatura: 'Is', orden: 23),
      Libro(idLibro: 24, nombre: 'Jeremías', abreviatura: 'Jer', orden: 24),
      Libro(idLibro: 25, nombre: 'Lamentaciones', abreviatura: 'Lm', orden: 25),
      Libro(idLibro: 26, nombre: 'Ezequiel', abreviatura: 'Ez', orden: 26),
      Libro(idLibro: 27, nombre: 'Daniel', abreviatura: 'Dn', orden: 27),
      Libro(idLibro: 28, nombre: 'Oseas', abreviatura: 'Os', orden: 28),
      Libro(idLibro: 29, nombre: 'Joel', abreviatura: 'Jl', orden: 29),
      Libro(idLibro: 30, nombre: 'Amós', abreviatura: 'Am', orden: 30),
      Libro(idLibro: 31, nombre: 'Abdías', abreviatura: 'Abd', orden: 31),
      Libro(idLibro: 32, nombre: 'Jonás', abreviatura: 'Jon', orden: 32),
      Libro(idLibro: 33, nombre: 'Miqueas', abreviatura: 'Mi', orden: 33),
      Libro(idLibro: 34, nombre: 'Nahum', abreviatura: 'Nah', orden: 34),
      Libro(idLibro: 35, nombre: 'Habacuc', abreviatura: 'Hab', orden: 35),
      Libro(idLibro: 36, nombre: 'Sofonías', abreviatura: 'Sof', orden: 36),
      Libro(idLibro: 37, nombre: 'Hageo', abreviatura: 'Hag', orden: 37),
      Libro(idLibro: 38, nombre: 'Zacarías', abreviatura: 'Zac', orden: 38),
      Libro(idLibro: 39, nombre: 'Malaquías', abreviatura: 'Mal', orden: 39),
      // New Testament (27 books)
      Libro(idLibro: 40, nombre: 'Mateo', abreviatura: 'Mt', orden: 40),
      Libro(idLibro: 41, nombre: 'Marcos', abreviatura: 'Mc', orden: 41),
      Libro(idLibro: 42, nombre: 'Lucas', abreviatura: 'Lc', orden: 42),
      Libro(idLibro: 43, nombre: 'Juan', abreviatura: 'Jn', orden: 43),
      Libro(idLibro: 44, nombre: 'Hechos', abreviatura: 'Hch', orden: 44),
      Libro(idLibro: 45, nombre: 'Romanos', abreviatura: 'Ro', orden: 45),
      Libro(idLibro: 46, nombre: '1 Corintios', abreviatura: '1Co', orden: 46),
      Libro(idLibro: 47, nombre: '2 Corintios', abreviatura: '2Co', orden: 47),
      Libro(idLibro: 48, nombre: 'Gálatas', abreviatura: 'Gá', orden: 48),
      Libro(idLibro: 49, nombre: 'Efesios', abreviatura: 'Ef', orden: 49),
      Libro(idLibro: 50, nombre: 'Filipenses', abreviatura: 'Fil', orden: 50),
      Libro(idLibro: 51, nombre: 'Colosenses', abreviatura: 'Col', orden: 51),
      Libro(
        idLibro: 52,
        nombre: '1 Tesalonicenses',
        abreviatura: '1Ts',
        orden: 52,
      ),
      Libro(
        idLibro: 53,
        nombre: '2 Tesalonicenses',
        abreviatura: '2Ts',
        orden: 53,
      ),
      Libro(idLibro: 54, nombre: '1 Timoteo', abreviatura: '1Ti', orden: 54),
      Libro(idLibro: 55, nombre: '2 Timoteo', abreviatura: '2Ti', orden: 55),
      Libro(idLibro: 56, nombre: 'Tito', abreviatura: 'Tit', orden: 56),
      Libro(idLibro: 57, nombre: 'Filemón', abreviatura: 'Flm', orden: 57),
      Libro(idLibro: 58, nombre: 'Hebreos', abreviatura: 'He', orden: 58),
      Libro(idLibro: 59, nombre: 'Santiago', abreviatura: 'Stg', orden: 59),
      Libro(idLibro: 60, nombre: '1 Pedro', abreviatura: '1P', orden: 60),
      Libro(idLibro: 61, nombre: '2 Pedro', abreviatura: '2P', orden: 61),
      Libro(idLibro: 62, nombre: '1 Juan', abreviatura: '1Jn', orden: 62),
      Libro(idLibro: 63, nombre: '2 Juan', abreviatura: '2Jn', orden: 63),
      Libro(idLibro: 64, nombre: '3 Juan', abreviatura: '3Jn', orden: 64),
      Libro(idLibro: 65, nombre: 'Judas', abreviatura: 'Jud', orden: 65),
      Libro(idLibro: 66, nombre: 'Apocalipsis', abreviatura: 'Ap', orden: 66),
    ];
  }

  Future<List<AudioCapitulo>> getCapitulosConAudio(int idLibro) async {
    // Web fallback
    if (kIsWeb) {
      return _getFallbackAudioChapters(idLibro);
    }

    // Mobile/desktop: try database first
    final db = await _dbHelper!.database;
    final maps = await db.query(
      'audio_capitulo',
      where: 'id_libro = ?',
      whereArgs: [idLibro],
      orderBy: 'capitulo ASC',
    );

    // If database has data, use it
    if (maps.isNotEmpty) {
      final list = maps.map((m) => AudioCapitulo.fromMap(m)).toList();
      // Sanitize legacy placeholder URLs from older DBs
      return list.map((a) => _sanitizeAudioUrl(a)).toList();
    }

    // Fallback: generate demo audio chapters for common books
    return _getFallbackAudioChapters(idLibro);
  }

  /// Generate WordProject.org audio URL for a book and chapter
  /// Based on: https://www.wordproject.org/bibles/audio/06_spanish/index.htm
  /// Note: WordProject.org may have CORS restrictions or require different URL formats
  /// This function returns null if URL format is uncertain, allowing fallback to assets
  String? _getWordProjectAudioUrl(int idLibro, int capitulo) {
    // Confirmed direct audio pattern observed on WordProject Spanish pages:
    // http://audio1.wordfree.net/bibles/app/audio/6/{bookId}/{chapter}.mp3
    // where bookId is 1..66 (Génesis=1, Mateo=40, etc.) and chapter is 1..N
    if (idLibro < 1 || idLibro > 66) return null;
    if (capitulo < 1) return null;
    // Prefer HTTPS to avoid cleartext network restrictions on modern Android/iOS/Web
    return 'https://audio1.wordfree.net/bibles/app/audio/6/$idLibro/$capitulo.mp3';
  }

  /// Generate fallback audio chapters with real URLs from WordProject.org
  List<AudioCapitulo> _getFallbackAudioChapters(int idLibro) {
    // Number of chapters per book (complete Bible)
    final chaptersPerBook = <int, int>{
      // Old Testament
      1: 50, // Génesis
      2: 40, // Éxodo
      3: 27, // Levítico
      4: 36, // Números
      5: 34, // Deuteronomio
      6: 24, // Josué
      7: 21, // Jueces
      8: 4, // Rut
      9: 31, // 1 Samuel
      10: 24, // 2 Samuel
      11: 22, // 1 Reyes
      12: 25, // 2 Reyes
      13: 29, // 1 Crónicas
      14: 36, // 2 Crónicas
      15: 10, // Esdras
      16: 13, // Nehemías
      17: 10, // Ester
      18: 42, // Job
      19: 150, // Salmos
      20: 31, // Proverbios
      21: 12, // Eclesiastés
      22: 8, // Cantares
      23: 66, // Isaías
      24: 52, // Jeremías
      25: 5, // Lamentaciones
      26: 48, // Ezequiel
      27: 12, // Daniel
      28: 14, // Oseas
      29: 3, // Joel
      30: 9, // Amós
      31: 1, // Abdías
      32: 4, // Jonás
      33: 7, // Miqueas
      34: 3, // Nahum
      35: 3, // Habacuc
      36: 3, // Sofonías
      37: 2, // Hageo
      38: 14, // Zacarías
      39: 4, // Malaquías
      // New Testament
      40: 28, // Mateo
      41: 16, // Marcos
      42: 24, // Lucas
      43: 21, // Juan
      44: 28, // Hechos
      45: 16, // Romanos
      46: 16, // 1 Corintios
      47: 13, // 2 Corintios
      48: 6, // Gálatas
      49: 6, // Efesios
      50: 4, // Filipenses
      51: 4, // Colosenses
      52: 5, // 1 Tesalonicenses
      53: 3, // 2 Tesalonicenses
      54: 6, // 1 Timoteo
      55: 4, // 2 Timoteo
      56: 3, // Tito
      57: 1, // Filemón
      58: 13, // Hebreos
      59: 5, // Santiago
      60: 5, // 1 Pedro
      61: 3, // 2 Pedro
      62: 5, // 1 Juan
      63: 1, // 2 Juan
      64: 1, // 3 Juan
      65: 1, // Judas
      66: 22, // Apocalipsis
    };

    final totalChapters = chaptersPerBook[idLibro];
    if (totalChapters == null) {
      // If book not found, return empty list
      return [];
    }

    final chapters = <AudioCapitulo>[];

    // Generate all chapters with WordProject.org URLs or asset fallback
    for (int i = 1; i <= totalChapters; i++) {
      final audioUrl = _getWordProjectAudioUrl(idLibro, i);

      // If URL is available, use it; otherwise use asset demo as fallback
      chapters.add(
        AudioCapitulo(
          idLibro: idLibro,
          capitulo: i,
          localPath: audioUrl == null
              ? 'assets/audio/demo.mp3'
              : null, // Use asset if URL not available
          url: audioUrl, // WordProject.org URL (null if format uncertain)
          duracionSegundos:
              null, // Duration unknown, will be determined by player
          downloadStatus: AudioDownloadStatus.remote,
        ),
      );
    }

    return chapters;
  }

  Future<AudioCapitulo?> getAudioParaCapitulo(int idLibro, int capitulo) async {
    // Web fallback
    if (kIsWeb) {
      final list = await getCapitulosConAudio(idLibro);
      try {
        return list.firstWhere((e) => e.capitulo == capitulo);
      } catch (_) {
        return null;
      }
    }

    // Mobile/desktop: try database first
    final db = await _dbHelper!.database;
    final maps = await db.query(
      'audio_capitulo',
      where: 'id_libro = ? AND capitulo = ?',
      whereArgs: [idLibro, capitulo],
      limit: 1,
    );

    // If database has data, use it
    if (maps.isNotEmpty) {
      return _sanitizeAudioUrl(AudioCapitulo.fromMap(maps.first));
    }

    // Fallback: generate audio for this chapter (with asset demo as fallback)
    final fallbackChapters = _getFallbackAudioChapters(idLibro);
    try {
      return fallbackChapters.firstWhere((e) => e.capitulo == capitulo);
    } catch (_) {
      // If chapter doesn't exist in fallback, create one with asset demo
      final audioUrl = _getWordProjectAudioUrl(idLibro, capitulo);
      return AudioCapitulo(
        idLibro: idLibro,
        capitulo: capitulo,
        localPath: audioUrl == null ? 'assets/audio/demo.mp3' : null,
        url: audioUrl,
        duracionSegundos: null,
        downloadStatus: AudioDownloadStatus.remote,
      );
    }
  }

  /// Replace placeholder/invalid URLs with the correct WordProject URL
  AudioCapitulo _sanitizeAudioUrl(AudioCapitulo audio) {
    final url = audio.url;
    final needsFix = url == null || url.isEmpty || url.contains('example.com');
    if (!needsFix) return audio;
    final generated = _getWordProjectAudioUrl(audio.idLibro, audio.capitulo);
    return audio.copyWith(
      url: generated,
      localPath: generated != null ? null : audio.localPath,
      downloadStatus: AudioDownloadStatus.remote,
    );
  }

  /// Sync audio metadata from API Gateway
  Future<void> syncMetadata({String version = 'rv1960'}) async {
    if (kIsWeb || _syncService == null) {
      throw UnsupportedError('Metadata sync not supported on web platform');
    }
    await _syncService!.syncMetadata(version: version);
  }

  /// Check if metadata sync is needed
  Future<bool> needsSync() async {
    if (kIsWeb || _syncService == null) {
      return false;
    }
    return await _syncService!.needsSync();
  }

  /// Download a single audio chapter
  Future<void> downloadAudio(AudioCapitulo audio) async {
    if (kIsWeb || _downloadService == null) {
      throw UnsupportedError('Audio download not supported on web platform');
    }
    await _downloadService!.downloadAudio(audio);
  }

  /// Cancel an ongoing download
  Future<void> cancelDownload(AudioCapitulo audio) async {
    if (kIsWeb || _downloadService == null) {
      throw UnsupportedError('Cancel download not supported on web platform');
    }
    await _downloadService!.cancelDownload(audio);
  }

  /// Delete a downloaded audio file
  Future<void> deleteDownloadedAudio(AudioCapitulo audio) async {
    if (kIsWeb || _downloadService == null) {
      throw UnsupportedError(
        'Delete downloaded audio not supported on web platform',
      );
    }
    await _downloadService!.deleteDownloadedAudio(audio);
  }

  /// Get download progress for an audio
  Future<double?> getDownloadProgress(AudioCapitulo audio) async {
    if (kIsWeb || _downloadService == null) {
      return null;
    }
    return await _downloadService!.getDownloadProgress(audio);
  }

  /// Update download status in database
  Future<void> updateDownloadStatus(
    AudioCapitulo audio,
    AudioDownloadStatus status,
  ) async {
    if (kIsWeb) return;
    final db = await _dbHelper!.database;
    await db.update(
      'audio_capitulo',
      {'download_status': status.dbValue},
      where: 'id_audio = ?',
      whereArgs: [audio.idAudio],
    );
  }

  /// Get all downloaded audios
  Future<List<AudioCapitulo>> getDownloadedAudios() async {
    if (kIsWeb) return const [];
    final db = await _dbHelper!.database;
    final maps = await db.query(
      'audio_capitulo',
      where: 'download_status = ?',
      whereArgs: [AudioDownloadStatus.complete.dbValue],
      orderBy: 'id_libro ASC, capitulo ASC',
    );
    return maps.map((m) => AudioCapitulo.fromMap(m)).toList();
  }
}
