import '../../core/database/database_helper.dart';
import '../models/versiculo_model.dart';

class VersiculoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Versiculo>> getAllVersiculos() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT v.*, c.nombre as nombre_categoria 
      FROM versiculo v 
      LEFT JOIN categoria c ON v.id_categoria = c.id_categoria
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
      SELECT v.*, c.nombre as nombre_categoria 
      FROM versiculo v 
      LEFT JOIN categoria c ON v.id_categoria = c.id_categoria
      WHERE v.id_versiculo = ?
    ''',
      [id],
    );

    if (maps.isNotEmpty) {
      return Versiculo.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Versiculo>> getVersiculosByCategoria(int idCategoria) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT v.*, c.nombre as nombre_categoria 
      FROM versiculo v 
      LEFT JOIN categoria c ON v.id_categoria = c.id_categoria
      WHERE v.id_categoria = ?
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
      SELECT v.*, c.nombre as nombre_categoria 
      FROM versiculo v 
      LEFT JOIN categoria c ON v.id_categoria = c.id_categoria
      WHERE v.texto LIKE ? OR v.referencia LIKE ?
      ORDER BY v.id_versiculo
    ''',
      ['%$query%', '%$query%'],
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
}
