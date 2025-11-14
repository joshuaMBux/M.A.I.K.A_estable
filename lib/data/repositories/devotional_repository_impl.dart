import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/devotional.dart';
import '../../domain/repositories/devotional_repository.dart';

class DevotionalRepositoryImpl implements DevotionalRepository {
  final DatabaseHelper? _dbHelper = kIsWeb ? null : DatabaseHelper();

  final List<Devotional> _webFallback = [
    Devotional(
      id: 1,
      title: 'El amor que transforma',
      content:
          'Reflexiona sobre el amor incondicional de Dios que cambia nuestra perspectiva y renueva el coraz\u00f3n. Permite que cada acci\u00f3n cotidiana sea guiada por ese amor que recibes de Cristo.',
      date: DateTime.now(),
      author: 'Maika',
      verseReference: '1 Corintios 13:4-5',
      verseText:
          'El amor es sufrido, es benigno; el amor no tiene envidia, el amor no es jactancioso, no se envanece; no hace nada indebido, no busca lo suyo.',
    ),
    Devotional(
      id: 2,
      title: 'Esperanza en el desierto',
      content:
          'En las estaciones secas recuerda que Dios provee manantiales de vida. Aun cuando no distingas el camino, \u00c9l te sustenta y abre sendas nuevas.',
      date: DateTime.now().subtract(const Duration(days: 1)),
      author: 'Maika',
      verseReference: 'Isa\u00edas 43:19',
      verseText:
          'He aqu\u00ed que yo hago cosa nueva; pronto saldr\u00e1 a luz; \u00bfno la conocer\u00e9is? Otra vez abrir\u00e9 camino en el desierto, y r\u00edos en la soledad.',
    ),
  ];

  @override
  Future<Devotional?> getTodayDevotional() async {
    if (kIsWeb) {
      return _webFallback.isEmpty ? null : _webFallback.first;
    }

    final db = await _dbHelper!.database;
    final today = DateTime.now().toIso8601String().split('T').first;

    final todayResult = await db.rawQuery(
      '''
      SELECT d.*, v.capitulo, v.versiculo AS versiculo_num, v.texto, 
             l.nombre AS nombre_libro, l.abreviatura 
      FROM devocional d
      LEFT JOIN versiculo v ON d.id_versiculo = v.id_versiculo
      LEFT JOIN libro l ON v.id_libro = l.id_libro
      WHERE d.fecha = ?
      ORDER BY d.fecha DESC
      LIMIT 1
      ''',
      [today],
    );

    if (todayResult.isNotEmpty) {
      return _mapRowToDevotional(todayResult.first);
    }

    final latestResult = await db.rawQuery('''
      SELECT d.*, v.capitulo, v.versiculo AS versiculo_num, v.texto, 
             l.nombre AS nombre_libro, l.abreviatura 
      FROM devocional d
      LEFT JOIN versiculo v ON d.id_versiculo = v.id_versiculo
      LEFT JOIN libro l ON v.id_libro = l.id_libro
      ORDER BY d.fecha DESC
      LIMIT 1
      ''');

    if (latestResult.isEmpty) {
      return null;
    }

    return _mapRowToDevotional(latestResult.first);
  }

  @override
  Future<List<Devotional>> getRecentDevotionals({int limit = 10}) async {
    if (kIsWeb) {
      return _webFallback.take(limit).toList();
    }

    final db = await _dbHelper!.database;
    final results = await db.rawQuery(
      '''
      SELECT d.*, v.capitulo, v.versiculo AS versiculo_num, v.texto, 
             l.nombre AS nombre_libro, l.abreviatura 
      FROM devocional d
      LEFT JOIN versiculo v ON d.id_versiculo = v.id_versiculo
      LEFT JOIN libro l ON v.id_libro = l.id_libro
      ORDER BY d.fecha DESC, d.id_devocional DESC
      LIMIT ?
      ''',
      [limit],
    );

    return results.map(_mapRowToDevotional).toList();
  }

  @override
  Future<Devotional?> getDevotionalById(int id) async {
    if (kIsWeb) {
      return _webFallback.firstWhere(
        (devotional) => devotional.id == id,
        orElse: () => _webFallback.first,
      );
    }

    final db = await _dbHelper!.database;
    final result = await db.rawQuery(
      '''
      SELECT d.*, v.capitulo, v.versiculo AS versiculo_num, v.texto, 
             l.nombre AS nombre_libro, l.abreviatura 
      FROM devocional d
      LEFT JOIN versiculo v ON d.id_versiculo = v.id_versiculo
      LEFT JOIN libro l ON v.id_libro = l.id_libro
      WHERE d.id_devocional = ?
      LIMIT 1
      ''',
      [id],
    );

    if (result.isEmpty) {
      return null;
    }

    return _mapRowToDevotional(result.first);
  }

  Devotional _mapRowToDevotional(Map<String, dynamic> row) {
    final id = row['id_devocional'] as int? ?? 0;
    final title = (row['titulo'] as String?)?.trim().isNotEmpty == true
        ? row['titulo'] as String
        : 'Devocional $id';
    final content = (row['cuerpo'] as String?)?.trim().isNotEmpty == true
        ? row['cuerpo'] as String
        : 'Contenido no disponible.';
    final dateString = row['fecha'] as String?;
    final date = dateString != null
        ? DateTime.tryParse(dateString) ?? DateTime.now()
        : DateTime.now();

    final bookName = row['nombre_libro'] as String?;
    final abbreviation = row['abreviatura'] as String?;
    final chapter = row['capitulo'] as int?;
    final verseNum = row['versiculo_num'] as int?;

    String? reference;
    if (bookName != null && chapter != null) {
      final shortBook = abbreviation?.isNotEmpty == true
          ? abbreviation!
          : bookName;
      reference = verseNum != null
          ? '$shortBook $chapter:$verseNum'
          : '$shortBook $chapter';
    }

    final verseText = row['texto'] as String?;

    return Devotional(
      id: id,
      title: title,
      content: content,
      date: date,
      author: row['autor'] as String?,
      verseReference: reference,
      verseText: verseText,
    );
  }
}
