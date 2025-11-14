import '../../core/database/database_helper.dart';
import '../models/favorito_model.dart';

class FavoritoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Favorito>> getFavoritosByUsuario(int idUsuario) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT f.*, v.texto as texto_versiculo, v.referencia as referencia_versiculo
      FROM favorito f
      JOIN versiculo v ON f.id_versiculo = v.id_versiculo
      WHERE f.id_usuario = ?
      ORDER BY f.fecha_agregado DESC
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
      'fecha_agregado': DateTime.now().toIso8601String(),
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

  Future<int> deleteFavorito(int idFavorito) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'favorito',
      where: 'id_favorito = ?',
      whereArgs: [idFavorito],
    );
  }
}
