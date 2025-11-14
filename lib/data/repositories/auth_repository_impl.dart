import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import 'usuario_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  @override
  Future<User> login(String email, String password) async {
    // Simulación de login - en producción esto sería una llamada a API
    await Future.delayed(const Duration(seconds: 1));

    // Buscar usuario en la base de datos
    final usuario = await _usuarioRepository.login(email, password);

    if (usuario != null) {
      // Convertir Usuario a User
      final user = UserModel(
        id: usuario.idUsuario.toString(),
        name: usuario.nombre,
        email: usuario.email ?? 'usuario@maika.com',
        createdAt:
            usuario.fechaNacimiento ??
            DateTime.now().subtract(const Duration(days: 30)),
        lastLogin: DateTime.now(),
      );

      // Guardar token simulado
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_token', 'demo_token_123');
      await prefs.setString('user_data', user.toJson().toString());
      await prefs.setInt('user_id', usuario.idUsuario!);

      return user;
    } else {
      // Si no existe, crear usuario demo
      final user = UserModel(
        id: '1',
        name: 'Usuario Demo',
        email: email,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastLogin: DateTime.now(),
      );

      // Guardar token simulado
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_token', 'demo_token_123');
      await prefs.setString('user_data', user.toJson().toString());
      await prefs.setInt('user_id', 1);

      return user;
    }
  }

  @override
  Future<User> register(String name, String email, String password) async {
    // Simulación de registro
    await Future.delayed(const Duration(seconds: 1));

    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_token', 'demo_token_123');
    await prefs.setString('user_data', user.toJson().toString());

    return user;
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
    await prefs.remove('user_data');
  }

  @override
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      // En una implementación real, parsearías el JSON
      return UserModel(
        id: '1',
        name: 'Usuario Demo',
        email: 'demo@example.com',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastLogin: DateTime.now(),
      );
    }
    return null;
  }

  @override
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token') != null;
  }
}
