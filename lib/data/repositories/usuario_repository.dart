import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../models/usuario_model.dart';

class UsuarioRepository {
  final DatabaseHelper? _dbHelper = kIsWeb ? null : DatabaseHelper();

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<int> insertUsuario(Usuario usuario) async {
    if (kIsWeb) {
      // Simular inserción en web
      return 1;
    }
    final db = await _dbHelper!.database;
    final data = usuario.toMap();
    if (usuario.pwd != null && usuario.pwd!.isNotEmpty) {
      data['pwd'] = _hashPassword(usuario.pwd!);
    }
    return await db.insert('usuario', data);
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
    // Primero intentar con contraseña hasheada (nuevo formato)
    final hashed = _hashPassword(password);
    List<Map<String, dynamic>> maps = await db.query(
      'usuario',
      where: 'email = ? AND pwd = ?',
      whereArgs: [email, hashed],
    );

    // Fallback: soportar usuarios antiguos con contraseña en texto plano
    if (maps.isEmpty) {
      maps = await db.query(
        'usuario',
        where: 'email = ? AND pwd = ?',
        whereArgs: [email, password],
      );
    }

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
    final data = usuario.toMap();
    if (usuario.pwd != null && usuario.pwd!.isNotEmpty) {
      data['pwd'] = _hashPassword(usuario.pwd!);
    }
    return await db.update(
      'usuario',
      data,
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
