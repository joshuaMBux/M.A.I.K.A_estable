import '../../core/database/database_helper.dart';
import '../models/favorito_model.dart';

class FavoritoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Favorito>> getFavoritosByUsuario(int idUsuario) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT
        f.id_favorito,
        f.id_usuario,
        f.id_versiculo,
        f.creado_en,
        v.texto AS texto_versiculo,
        printf('%s %d:%d', l.abreviatura, v.capitulo, v.versiculo)
          AS referencia_versiculo
      FROM favorito f
      JOIN versiculo v ON f.id_versiculo = v.id_versiculo
      JOIN libro l ON v.id_libro = l.id_libro
      WHERE f.id_usuario = ?
      ORDER BY f.creado_en DESC
      ''',
      [idUsuario],
    );

    return List.generate(maps.length, (i) {
      return Favorito.fromMap(maps[i]);
    });
  }

  Future<bool> isFavorito(int idUsuario, int idVersiculo) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorito',
      where: 'id_usuario = ? AND id_versiculo = ?',
      whereArgs: [idUsuario, idVersiculo],
    );

    return maps.isNotEmpty;
  }

  Future<int> addFavorito(int idUsuario, int idVersiculo) async {
    final db = await _dbHelper.database;
    return await db.insert('favorito', {
      'id_usuario': idUsuario,
      'id_versiculo': idVersiculo,
      'creado_en': DateTime.now().toIso8601String(),
    });
  }

  Future<int> removeFavorito(int idUsuario, int idVersiculo) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'favorito',
      where: 'id_usuario = ? AND id_versiculo = ?',
      whereArgs: [idUsuario, idVersiculo],
    );
  }

  Future<int> toggleFavorito(int idUsuario, int idVersiculo) async {
    final isFav = await isFavorito(idUsuario, idVersiculo);
    if (isFav) {
      return await removeFavorito(idUsuario, idVersiculo);
    } else {
      return await addFavorito(idUsuario, idVersiculo);
    }
  }

  Future<int> toggleFavoritoByReference({
    required int idUsuario,
    required String libroNombre,
    required int capitulo,
    required int versiculo,
    required String texto,
  }) async {
    final db = await _dbHelper.database;

    final libros = await db.query(
      'libro',
      where: 'nombre = ?',
      whereArgs: [libroNombre],
      limit: 1,
    );

    if (libros.isEmpty) {
      throw Exception('No se encontro el libro $libroNombre en la base de datos');
    }

    final idLibro = libros.first['id_libro'] as int;

    final existentes = await db.query(
      'versiculo',
      where: 'id_libro = ? AND capitulo = ? AND versiculo = ?',
      whereArgs: [idLibro, capitulo, versiculo],
      limit: 1,
    );

    int idVersiculo;
    if (existentes.isNotEmpty) {
      idVersiculo = existentes.first['id_versiculo'] as int;
    } else {
      idVersiculo = await db.insert('versiculo', {
        'id_libro': idLibro,
        'capitulo': capitulo,
        'versiculo': versiculo,
        'texto': texto,
        'version': 'RVR1960',
      });
    }

    return toggleFavorito(idUsuario, idVersiculo);
  }

  Future<int> deleteFavorito(int idFavorito) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'favorito',
      where: 'id_favorito = ?',
      whereArgs: [idFavorito],
    );
  }
}
