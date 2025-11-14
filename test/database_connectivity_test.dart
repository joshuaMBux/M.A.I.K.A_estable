import 'package:flutter_test/flutter_test.dart';
import 'package:maika_app/core/database/database_helper.dart';
import 'package:maika_app/data/models/usuario_model.dart';
import 'package:maika_app/data/models/versiculo_model.dart';
import 'package:maika_app/data/repositories/usuario_repository.dart';
import 'package:maika_app/data/repositories/versiculo_repository.dart';
import 'package:maika_app/data/repositories/favorito_repository.dart';

void main() {
  group('Database Connectivity Tests', () {
    late DatabaseHelper dbHelper;
    late UsuarioRepository usuarioRepo;
    late VersiculoRepository versiculoRepo;
    late FavoritoRepository favoritoRepo;

    setUpAll(() async {
      dbHelper = DatabaseHelper();
      usuarioRepo = UsuarioRepository();
      versiculoRepo = VersiculoRepository();
      favoritoRepo = FavoritoRepository();

      // Initialize database
      await dbHelper.database;
    });

    tearDownAll(() async {
      await dbHelper.close();
    });

    test('Database initialization should work', () async {
      final db = await dbHelper.database;
      expect(db, isNotNull);
      expect(db.isOpen, isTrue);
    });

    test('Usuario CRUD operations should work', () async {
      // Test insert
      final usuario = Usuario(
        nombre: 'Test User',
        email: 'test@example.com',
        pwd: 'password123',
        rol: 'joven',
      );

      final id = await usuarioRepo.insertUsuario(usuario);
      expect(id, greaterThan(0));

      // Test get by email
      final retrievedUsuario = await usuarioRepo.getUsuarioByEmail(
        'test@example.com',
      );
      expect(retrievedUsuario, isNotNull);
      expect(retrievedUsuario!.nombre, equals('Test User'));
      expect(retrievedUsuario.email, equals('test@example.com'));

      // Test login
      final loginUsuario = await usuarioRepo.login(
        'test@example.com',
        'password123',
      );
      expect(loginUsuario, isNotNull);
      expect(loginUsuario!.nombre, equals('Test User'));

      // Test update
      final updatedUsuario = Usuario(
        idUsuario: retrievedUsuario.idUsuario,
        nombre: 'Updated User',
        email: 'test@example.com',
        pwd: 'password123',
        rol: 'joven',
      );

      final updateResult = await usuarioRepo.updateUsuario(updatedUsuario);
      expect(updateResult, greaterThan(0));

      // Test delete
      final deleteResult = await usuarioRepo.deleteUsuario(
        retrievedUsuario.idUsuario!,
      );
      expect(deleteResult, greaterThan(0));
    });

    test('Versiculo operations should work', () async {
      // Test get all versiculos
      final versiculos = await versiculoRepo.getAllVersiculos();
      expect(versiculos, isNotEmpty);

      // Test get versiculo by id
      final versiculo = await versiculoRepo.getVersiculoById(1);
      expect(versiculo, isNotNull);
      expect(versiculo!.texto, isNotEmpty);

      // Test search versiculos
      final searchResults = await versiculoRepo.searchVersiculos('amor');
      expect(searchResults, isA<List<Versiculo>>());

      // Test get versiculo del dia
      final versiculoDelDia = await versiculoRepo.getVersiculoDelDia();
      expect(versiculoDelDia, isNotNull);
    });

    test('Favorito operations should work', () async {
      // Create a test user first
      final usuario = Usuario(
        nombre: 'Test User for Favorites',
        email: 'favorites@example.com',
        pwd: 'password123',
        rol: 'joven',
      );

      final userId = await usuarioRepo.insertUsuario(usuario);
      expect(userId, greaterThan(0));

      // Test add favorite
      final addResult = await favoritoRepo.addFavorito(userId, 1);
      expect(addResult, greaterThan(0));

      // Test check if favorite
      final isFavorite = await favoritoRepo.isFavorito(userId, 1);
      expect(isFavorite, isTrue);

      // Test get favorites by user
      final favorites = await favoritoRepo.getFavoritosByUsuario(userId);
      expect(favorites, isNotEmpty);
      expect(favorites.first.idVersiculo, equals(1));

      // Test toggle favorite
      final toggleResult = await favoritoRepo.toggleFavorito(userId, 1);
      expect(toggleResult, greaterThan(0));

      // Test remove favorite
      final removeResult = await favoritoRepo.removeFavorito(userId, 1);
      expect(removeResult, greaterThan(0));

      // Clean up
      await usuarioRepo.deleteUsuario(userId);
    });

    test('Database schema should be correct', () async {
      final db = await dbHelper.database;

      // Check if all required tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      final tableNames = tables
          .map((table) => table['name'] as String)
          .toList();

      expect(tableNames, contains('usuario'));
      expect(tableNames, contains('versiculo'));
      expect(tableNames, contains('favorito'));
      expect(tableNames, contains('libro'));
      expect(tableNames, contains('categoria'));
      expect(tableNames, contains('historial_conversacion'));
      expect(tableNames, contains('pregunta_frecuente'));
      expect(tableNames, contains('plan_lectura'));
      expect(tableNames, contains('devocional'));
      expect(tableNames, contains('audio_capitulo'));
      expect(tableNames, contains('actividad_usuario'));
      expect(tableNames, contains('racha_usuario'));
      expect(tableNames, contains('nota'));
      expect(tableNames, contains('versiculo_del_dia'));
      expect(tableNames, contains('quiz'));
      expect(tableNames, contains('pregunta_quiz'));
      expect(tableNames, contains('opcion_quiz'));
      expect(tableNames, contains('resultado_quiz'));
    });

    test('Initial data should be loaded', () async {
      // Check if books are loaded
      final db = await dbHelper.database;
      final books = await db.query('libro');
      expect(
        books.length,
        greaterThan(60),
      ); // Should have all 66 books of the Bible

      // Check if categories are loaded
      final categories = await db.query('categoria');
      expect(categories.length, greaterThan(5));

      // Check if sample verse is loaded
      final verses = await db.query('versiculo');
      expect(verses.length, greaterThan(0));

      // Check if sample FAQ is loaded
      final faqs = await db.query('pregunta_frecuente');
      expect(faqs.length, greaterThan(0));
    });
  });
}
