import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/verse.dart';
import '../../domain/repositories/verse_repository.dart';
import '../models/verse_model.dart';
import '../models/versiculo_model.dart';
import '../../core/database/database_helper.dart';
import 'versiculo_repository.dart';

/// Elimina etiquetas HTML basicas y normaliza espacios.
String stripHtml(String html) {
  // Quitar etiquetas
  final withoutTags = html.replaceAll(RegExp(r'<[^>]+>'), ' ');

  // Decodificar algunas entidades comunes
  var text = withoutTags
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");

  // Normalizar espacios
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

  return text;
}

class VerseRepositoryImpl implements VerseRepository {
  static const String _bibleBaseUrl = 'https://rest.api.bible/v1';
  static const String _bibleId = '48acedcf8595c754-02';
  static const String _apiKey = 'UtwpQ6QO3Ktn2U-lbmDko';

  final VersiculoRepository? _versiculoRepository;
  final http.Client _httpClient;

  List<Map<String, dynamic>>? _booksCache;

  VerseRepositoryImpl({
    VersiculoRepository? versiculoRepository,
    http.Client? httpClient,
  })  : _versiculoRepository = versiculoRepository,
        _httpClient = httpClient ?? http.Client();

  @override
  Future<List<Verse>> searchVerses(String query) async {
    // Implementacion futura: busqueda en SQLite.
    // Por ahora se mantiene la simulacion existente.
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      const VerseModel(
        id: '1',
        book: 'Juan',
        chapter: 3,
        verse: 16,
        text:
            'Porque de tal manera amo Dios al mundo, que ha dado a su Hijo unigenito, para que todo aquel que en el cree, no se pierda, mas tenga vida eterna.',
        translation: 'RVR1960',
        tags: ['amor', 'salvacion', 'vida eterna'],
      ),
      const VerseModel(
        id: '2',
        book: 'Salmos',
        chapter: 23,
        verse: 1,
        text: 'El Senor es mi pastor, nada me faltara.',
        translation: 'RVR1960',
        tags: ['confianza', 'provision', 'cuidado'],
      ),
    ];
  }

  @override
  Future<List<Verse>> getVersesByCategory(String category) async {
    // Implementacion futura: categorias en SQLite.
    await Future.delayed(const Duration(milliseconds: 300));

    return const [
      VerseModel(
        id: '3',
        book: 'Proverbios',
        chapter: 3,
        verse: 5,
        text:
            'Confia en el Senor con todo tu corazon, y no te apoyes en tu propia prudencia.',
        translation: 'RVR1960',
        tags: ['confianza', 'sabiduria'],
      ),
    ];
  }

  /// Carga un capitulo completo aplicando la estrategia de carga progresiva:
  /// 1) Verifica si el capitulo existe en SQLite.
  /// 2) Si no existe, lo descarga de la API, limpia HTML y lo guarda en SQLite.
  /// 3) Siempre devuelve los datos finales desde SQLite.
  @override
  Future<List<Verse>> getChapter(String book, int chapter) async {
    if (kIsWeb || _versiculoRepository == null) {
      throw UnsupportedError(
        'La carga progresiva de capitulos solo esta soportada en plataformas no web',
      );
    }

    final repo = _versiculoRepository!;

    final exists = await repo.chapterExists(book, chapter);

    if (!exists) {
      final versiculosFromApi =
          await _fetchChapterFromApi(book, chapter);

      if (versiculosFromApi.isNotEmpty) {
        await repo.saveVerses(versiculosFromApi);
      }
    }

    final storedVerses =
        await repo.getVersesByBookAndChapter(book, chapter);

    return storedVerses
        .map(
          (v) => Verse(
            id: v.idVersiculo?.toString() ??
                '${v.idLibro}_${v.capitulo}_${v.versiculo}',
            book: v.nombreLibro ?? book,
            chapter: v.capitulo,
            verse: v.versiculo,
            text: v.texto,
            translation: v.version,
            tags: const [],
            isFavorite: false,
          ),
        )
        .toList();
  }

  /// Obtiene un capitulo desde la API externa, limpia el HTML
  /// y devuelve una lista de [Versiculo] lista para persistir.
  Future<List<Versiculo>> _fetchChapterFromApi(
    String book,
    int chapter,
  ) async {
    if (kIsWeb || _versiculoRepository == null) {
      throw UnsupportedError(
        'fetchChapterFromApi solo esta soportado en plataformas no web',
      );
    }

    // Resolver id_libro en SQLite. Si ya hay versiculos de ese capitulo,
    // reutilizamos el id_libro del primero; si no, preguntamos la tabla libro.
    final existing =
        await _versiculoRepository!.getVersesByBookAndChapter(book, chapter);

    final int idLibro = existing.isNotEmpty
        ? existing.first.idLibro
        : await _resolveLibroId(book);

    // Resolver id de libro en la API (JHN, ROM, etc.).
    final apiBookId = await _resolveApiBookId(book);
    final chapterId = '$apiBookId.$chapter';

    final uri = Uri.parse(
      '$_bibleBaseUrl/bibles/$_bibleId/chapters/$chapterId?content-type=html',
    );

    final response = await _httpClient.get(
      uri,
      headers: {
        'api-key': _apiKey,
        'accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener capitulo $book $chapter: '
        '${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw Exception(
        'La respuesta de la API para $book $chapter no contiene datos',
      );
    }

    final content = data['content'] as String? ?? '';
    if (content.isEmpty) {
      throw Exception(
        'La respuesta de la API para $book $chapter no contiene contenido HTML',
      );
    }

    final verses = <Versiculo>[];

    // Buscar marcadores de versiculo: <span data-number="N" class="v">N</span>
    final spanRegex = RegExp(
      r'<span[^>]*data-number=\"(\d+)\"[^>]*class=\"v\"[^>]*>.*?<\/span>',
      caseSensitive: false,
    );

    final matches = spanRegex.allMatches(content).toList();

    if (matches.isEmpty) {
      // Fallback: guardar todo el contenido como versiculo 1
      final plain = stripHtml(content);
      if (plain.isNotEmpty) {
        verses.add(
          Versiculo(
            idLibro: idLibro,
            capitulo: chapter,
            versiculo: 1,
            texto: plain,
          ),
        );
      }
      return verses;
    }

    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final verseNumber =
          int.tryParse(match.group(1) ?? '') ?? (i + 1);

      final start = match.end;
      final end =
          i + 1 < matches.length ? matches[i + 1].start : content.length;

      final snippet = content.substring(start, end);
      final plainText = stripHtml(snippet);

      if (plainText.isEmpty) continue;

      verses.add(
        Versiculo(
          idLibro: idLibro,
          capitulo: chapter,
          versiculo: verseNumber,
          texto: plainText,
        ),
      );
    }

    return verses;
  }

  Future<String> _resolveApiBookId(String book) async {
    final normalized = _normalizeBookKey(book);

    if (_booksCache == null) {
      _booksCache = await _fetchBooksMetadata();
    }

    for (final item in _booksCache!) {
      final name = (item['name'] as String?) ?? '';
      final abbr = (item['abbreviation'] as String?) ?? '';

      if (_normalizeBookKey(name) == normalized ||
          _normalizeBookKey(abbr) == normalized) {
        return item['id'] as String;
      }
    }

    throw Exception(
      'No se pudo resolver el identificador de libro de API para "$book"',
    );
  }

  Future<List<Map<String, dynamic>>> _fetchBooksMetadata() async {
    final uri = Uri.parse('$_bibleBaseUrl/bibles/$_bibleId/books');

    final response = await _httpClient.get(
      uri,
      headers: {
        'api-key': _apiKey,
        'accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener lista de libros: '
        '${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>? ?? const [];

    return data.cast<Map<String, dynamic>>();
  }

  Future<int> _resolveLibroId(String book) async {
    final repo = _versiculoRepository;
    if (repo == null) {
      throw UnsupportedError('No hay repositorio de versiculos disponible');
    }

    final existing =
        await repo.getVersesByBookAndChapter(book, 1);
    if (existing.isNotEmpty) {
      return existing.first.idLibro;
    }

    // Si no hay versiculos aun, resolvemos contra la tabla libro.
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final lowerBook = book.toLowerCase();

    final rows = await db.query(
      'libro',
      columns: ['id_libro'],
      where: 'LOWER(nombre) = ? OR LOWER(abreviatura) = ?',
      whereArgs: [lowerBook, lowerBook],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw Exception('No se encontro el libro "$book" en SQLite');
    }

    return rows.first['id_libro'] as int;
  }

  String _normalizeBookKey(String input) {
    var value = input.toLowerCase().replaceAll(RegExp(r'\s+'), '');

    const accents = {
      'á': 'a',
      'ä': 'a',
      'à': 'a',
      'â': 'a',
      'é': 'e',
      'ë': 'e',
      'è': 'e',
      'ê': 'e',
      'í': 'i',
      'ï': 'i',
      'ì': 'i',
      'î': 'i',
      'ó': 'o',
      'ö': 'o',
      'ò': 'o',
      'ô': 'o',
      'ú': 'u',
      'ü': 'u',
      'ù': 'u',
      'û': 'u',
      'ñ': 'n',
    };

    accents.forEach((k, v) {
      value = value.replaceAll(k, v);
    });

    return value;
  }

  @override
  Future<List<Verse>> getFavoriteVerses() async {
    // Simular versiculos favoritos (se puede conectar luego a SQLite)
    return const [
      VerseModel(
        id: '1',
        book: 'Juan',
        chapter: 3,
        verse: 16,
        text:
            'Porque de tal manera amo Dios al mundo, que ha dado a su Hijo unigenito, para que todo aquel que en el cree, no se pierda, mas tenga vida eterna.',
        translation: 'RVR1960',
        tags: ['amor', 'salvacion', 'vida eterna'],
        isFavorite: true,
      ),
    ];
  }

  @override
  Future<void> toggleFavorite(String verseId) async {
    // Se mantiene implementacion con SharedPreferences para no romper favoritos existentes.
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorite_verses') ?? [];

    if (favorites.contains(verseId)) {
      favorites.remove(verseId);
    } else {
      favorites.add(verseId);
    }

    await prefs.setStringList('favorite_verses', favorites);
  }

  @override
  Future<List<String>> getCategories() async {
    // Categorias actuales (hardcoded) ? mas adelante se pueden mover a SQLite.
    return const [
      'Amor',
      'Fe',
      'Esperanza',
      'Sabiduria',
      'Salvacion',
      'Gratitud',
      'Perdon',
      'Paz',
    ];
  }

  @override
  Future<Verse?> getVerseOfTheDay() async {
    // Por ahora se mantiene Juan 3:16 como versiculo del dia (mock).
    return const VerseModel(
      id: '1',
      book: 'Juan',
      chapter: 3,
      verse: 16,
      text:
          'Porque de tal manera amo Dios al mundo, que ha dado a su Hijo unigenito, para que todo aquel que en el cree, no se pierda, mas tenga vida eterna.',
      translation: 'RVR1960',
      tags: ['amor', 'salvacion', 'vida eterna'],
      isFavorite: false,
    );
  }
}
