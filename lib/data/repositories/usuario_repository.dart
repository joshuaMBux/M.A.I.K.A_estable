import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../models/usuario_model.dart';

class UsuarioRepository {
  final DatabaseHelper? _dbHelper = kIsWeb ? null : DatabaseHelper();

  Future<int> insertUsuario(Usuario usuario) async {
    if (kIsWeb) {
      // Simular inserción en web
      return 1;
    }
    final db = await _dbHelper!.database;
    return await db.insert('usuario', usuario.toMap());
  }

  Future<Usuario?> getUsuarioByEmail(String email) async {
    if (kIsWeb) {
      // Simular usuario demo en web
      if (email == 'demo@example.com') {
        return Usuario(
          idUsuario: 1,
          nombre: 'Usuario Demo',
          email: email,
          pwd: 'demo123',
          rol: 'joven',
        );
      }
      return null;
    }
    final db = await _dbHelper!.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'usuario',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return Usuario.fromMap(maps.first);
    }
    return null;
  }

  Future<Usuario?> login(String email, String password) async {
    if (kIsWeb) {
      // Simular login en web
      if (email == 'demo@example.com' && password == 'demo123') {
        return Usuario(
          idUsuario: 1,
          nombre: 'Usuario Demo',
          email: email,
          pwd: password,
          rol: 'joven',
        );
      }
      return null;
    }
    final db = await _dbHelper!.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'usuario',
      where: 'email = ? AND pwd = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return Usuario.fromMap(maps.first);
    }
    return null;
  }

  Future<bool> emailExists(String email) async {
    final usuario = await getUsuarioByEmail(email);
    return usuario != null;
  }

  Future<int> updateUsuario(Usuario usuario) async {
    if (kIsWeb) {
      // Simular actualización en web
      return 1;
    }
    final db = await _dbHelper!.database;
    return await db.update(
      'usuario',
      usuario.toMap(),
      where: 'id_usuario = ?',
      whereArgs: [usuario.idUsuario],
    );
  }

  Future<int> deleteUsuario(int idUsuario) async {
    if (kIsWeb) {
      // Simular eliminación en web
      return 1;
    }
    final db = await _dbHelper!.database;
    return await db.delete(
      'usuario',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );
  }
}
