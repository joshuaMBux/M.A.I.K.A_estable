import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/category_matcher_service.dart';
import '../models/versiculo_model.dart';

class VersiculoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final CategoryMatcherService _categoryMatcher = CategoryMatcherService();

  Future<List<Versiculo>> getAllVersiculos() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        v.*,
        l.nombre AS nombre_libro,
        l.abreviatura AS abreviatura_libro,
        GROUP_CONCAT(c.nombre, ', ') AS nombre_categoria
      FROM versiculo v
      LEFT JOIN libro l ON v.id_libro = l.id_libro
      LEFT JOIN versiculo_categoria vc ON vc.id_versiculo = v.id_versiculo
      LEFT JOIN categoria c ON c.id_categoria = vc.id_categoria
      GROUP BY v.id_versiculo
      ORDER BY v.id_versiculo
    ''');

    return List.generate(maps.length, (i) {
      return Versiculo.fromMap(maps[i]);
    });
  }

  Future<Versiculo?> getVersiculoById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT
        v.*,
        l.nombre AS nombre_libro,
        l.abreviatura AS abreviatura_libro,
        GROUP_CONCAT(c.nombre, ', ') AS nombre_categoria
      FROM versiculo v
      LEFT JOIN libro l ON v.id_libro = l.id_libro
      LEFT JOIN versiculo_categoria vc ON vc.id_versiculo = v.id_versiculo
      LEFT JOIN categoria c ON c.id_categoria = vc.id_categoria
      WHERE v.id_versiculo = ?
      GROUP BY v.id_versiculo
      ''',
      [id],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    // Si más adelante el modelo soporta lista de categorías,
    // se puede leer map['nombre_categoria'] aquí.
    return Versiculo.fromMap(map);
  }

  Future<List<Versiculo>> getVersiculosByCategoria(int idCategoria) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT
        v.*,
        l.nombre AS nombre_libro,
        l.abreviatura AS abreviatura_libro,
        GROUP_CONCAT(c.nombre, ', ') AS nombre_categoria
      FROM versiculo v
      JOIN versiculo_categoria vc ON vc.id_versiculo = v.id_versiculo
      JOIN categoria c ON c.id_categoria = vc.id_categoria
      LEFT JOIN libro l ON v.id_libro = l.id_libro
      WHERE vc.id_categoria = ?
      GROUP BY v.id_versiculo
      ORDER BY v.id_versiculo
      ''',
      [idCategoria],
    );

    return List.generate(maps.length, (i) {
      return Versiculo.fromMap(maps[i]);
    });
  }

  Future<List<Versiculo>> searchVersiculos(String query) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT
        v.*,
        l.nombre AS nombre_libro,
        l.abreviatura AS abreviatura_libro,
        GROUP_CONCAT(c.nombre, ', ') AS nombre_categoria
      FROM versiculo v
      LEFT JOIN libro l ON v.id_libro = l.id_libro
      LEFT JOIN versiculo_categoria vc ON vc.id_versiculo = v.id_versiculo
      LEFT JOIN categoria c ON c.id_categoria = vc.id_categoria
      WHERE v.texto LIKE ?
      GROUP BY v.id_versiculo
      ORDER BY v.id_versiculo
      ''',
      ['%$query%'],
    );

    return List.generate(maps.length, (i) {
      return Versiculo.fromMap(maps[i]);
    });
  }

  Future<Versiculo?> getVersiculoDelDia() async {
    final db = await _dbHelper.database;
    // Obtener versículo aleatorio
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT v.*, c.nombre as nombre_categoria 
      FROM versiculo v 
      LEFT JOIN categoria c ON v.id_categoria = c.id_categoria
      ORDER BY RANDOM()
      LIMIT 1
    ''');

    if (maps.isNotEmpty) {
      return Versiculo.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertVersiculo(Versiculo versiculo) async {
    final db = await _dbHelper.database;
    return await db.insert('versiculo', versiculo.toMap());
  }

  Future<int> updateVersiculo(Versiculo versiculo) async {
    final db = await _dbHelper.database;
    return await db.update(
      'versiculo',
      versiculo.toMap(),
      where: 'id_versiculo = ?',
      whereArgs: [versiculo.idVersiculo],
    );
  }

  Future<int> deleteVersiculo(int idVersiculo) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'versiculo',
      where: 'id_versiculo = ?',
      whereArgs: [idVersiculo],
    );
  }

  /// Devuelve true si existe al menos un versículo
  /// para el [book] y [chapter] dados en SQLite.
  Future<bool> chapterExists(String book, int chapter) async {
    final db = await _dbHelper.database;
    final lowerBook = book.toLowerCase();

    // Resolver id_libro a partir del nombre o abreviatura
    final libroRows = await db.query(
      'libro',
      columns: ['id_libro'],
      where: 'LOWER(nombre) = ? OR LOWER(abreviatura) = ?',
      whereArgs: [lowerBook, lowerBook],
      limit: 1,
    );

    if (libroRows.isEmpty) {
      return false;
    }

    final idLibro = libroRows.first['id_libro'] as int;

    final countRows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM versiculo
      WHERE id_libro = ? AND capitulo = ?
      ''',
      [idLibro, chapter],
    );

    if (countRows.isEmpty) return false;
    final count = (countRows.first['count'] as int?) ?? 0;
    return count > 0;
  }

  /// Inserta en bloque una lista de versículos.
  /// Se asume que corresponden a un mismo capítulo.
  Future<void> saveVerses(List<Versiculo> verses) async {
    if (verses.isEmpty) return;
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // Cache local para evitar consultar la misma categoría muchas veces.
      final Map<String, int?> categoriaIdCache = {};

      for (final versiculo in verses) {
        final categorias =
            _categoryMatcher.matchCategories(versiculo.texto);

        // 1) Insertar (o asegurar) el versículo en la tabla versiculo
        final versiculoMap = versiculo.toMap();
        versiculoMap.remove('id_versiculo');

        await txn.insert(
          'versiculo',
          versiculoMap,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        // Recuperar id_versiculo garantizado (ya existía o se acaba de insertar)
        final versiculoRow = await txn.query(
          'versiculo',
          columns: ['id_versiculo'],
          where: 'id_libro = ? AND capitulo = ? AND versiculo = ?',
          whereArgs: [versiculo.idLibro, versiculo.capitulo, versiculo.versiculo],
          limit: 1,
        );

        if (versiculoRow.isEmpty) {
          // Si por alguna razón no se pudo recuperar, saltamos categorización.
          continue;
        }

        final idVersiculo = versiculoRow.first['id_versiculo'] as int;

        if (categorias.isEmpty) continue;

        // 2) Para cada categoría detectada, insertar relación versiculo_categoria
        for (final nombreCategoria in categorias) {
          final key = nombreCategoria.toLowerCase();

          int? idCategoria = categoriaIdCache[key];
          if (categoriaIdCache.containsKey(key) && idCategoria == null) {
            // Ya sabemos que esta categoría no existe en tabla categoria.
            continue;
          }

          if (idCategoria == null) {
            final rows = await txn.query(
              'categoria',
              columns: ['id_categoria'],
              where: 'LOWER(nombre) = ?',
              whereArgs: [key],
              limit: 1,
            );

            if (rows.isEmpty) {
              // Cacheamos null para no volver a consultar este nombre.
              categoriaIdCache[key] = null;
              continue;
            }

            idCategoria = rows.first['id_categoria'] as int;
            categoriaIdCache[key] = idCategoria;
          }

          await txn.insert(
            'versiculo_categoria',
            {
              'id_versiculo': idVersiculo,
              'id_categoria': idCategoria,
            },
            // PRIMARY KEY(id_versiculo, id_categoria) asegura unicidad;
            // IGNORE evita excepciones si ya existía la relación.
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    });
  }

  /// Obtiene todos los versículos de un capítulo concreto
  /// identificado por nombre/abreviatura de libro y número de capítulo.
  Future<List<Versiculo>> getVersesByBookAndChapter(
    String book,
    int chapter,
  ) async {
    final db = await _dbHelper.database;
    final lowerBook = book.toLowerCase();

    final libroRows = await db.query(
      'libro',
      columns: ['id_libro'],
      where: 'LOWER(nombre) = ? OR LOWER(abreviatura) = ?',
      whereArgs: [lowerBook, lowerBook],
      limit: 1,
    );

    if (libroRows.isEmpty) {
      return [];
    }

    final idLibro = libroRows.first['id_libro'] as int;

    final maps = await db.rawQuery(
      '''
      SELECT v.*, l.nombre AS nombre_libro, l.abreviatura AS abreviatura_libro
      FROM versiculo v
      JOIN libro l ON v.id_libro = l.id_libro
      WHERE v.id_libro = ? AND v.capitulo = ?
      ORDER BY v.versiculo
      ''',
      [idLibro, chapter],
    );

    return List.generate(maps.length, (i) => Versiculo.fromMap(maps[i]));
  }
}
