import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/reading_plan.dart';
import '../../domain/entities/reading_plan_day.dart';
import '../../domain/repositories/reading_plan_repository.dart';
import '../models/plan_item_model.dart';

class ReadingPlanRepositoryImpl implements ReadingPlanRepository {
  final DatabaseHelper? _dbHelper = kIsWeb ? null : DatabaseHelper();
  final Map<int, Set<int>> _webProgress = {};

  @override
  Future<int?> getDefaultPlanId() async {
    if (kIsWeb) {
      return 1;
    }

    final db = await _dbHelper!.database;
    final result = await db.query(
      'plan_lectura',
      columns: ['id_plan'],
      orderBy: 'id_plan ASC',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first['id_plan'] as int?;
  }

  @override
  Future<ReadingPlan> getPlanDetail({required int planId, int? userId}) async {
    if (kIsWeb) {
      return _getWebFallbackPlan(planId);
    }

    final resolvedUserId = await _resolveUserId(userId);
    final db = await _dbHelper!.database;

    final planMap = await db.query(
      'plan_lectura',
      where: 'id_plan = ?',
      whereArgs: [planId],
      limit: 1,
    );

    if (planMap.isEmpty) {
      throw Exception('Plan de lectura no encontrado');
    }

    final items = await db.rawQuery(
      '''
      SELECT pi.*, l.nombre AS nombre_libro, l.abreviatura 
      FROM plan_item pi
      LEFT JOIN libro l ON pi.id_libro = l.id_libro
      WHERE pi.id_plan = ?
      ORDER BY pi.dia ASC
      ''',
      [planId],
    );

    final completedRecords = await db.query(
      'plan_progreso_usuario',
      columns: ['dia'],
      where: 'id_usuario = ? AND id_plan = ? AND completado = 1',
      whereArgs: [resolvedUserId, planId],
    );

    final completedDays = completedRecords
        .map((row) => row['dia'] as int)
        .toSet();

    final planItems = items.map((map) => PlanItem.fromMap(map)).toList();

    final days =
        planItems
            .map(
              (item) => ReadingPlanDay(
                day: item.day,
                book: item.bookName ?? 'Lectura',
                startChapter: item.startChapter,
                startVerse: item.startVerse,
                endChapter: item.endChapter,
                endVerse: item.endVerse,
                comment: item.comment,
                completed: completedDays.contains(item.day),
              ),
            )
            .toList()
          ..sort((a, b) => a.day.compareTo(b.day));

    return ReadingPlan(
      id: planId,
      name: planMap.first['nombre'] as String,
      description: planMap.first['descripcion'] as String?,
      days: days,
    );
  }

  @override
  Future<void> toggleDayCompletion({
    required int planId,
    required int day,
    int? userId,
    required bool completed,
  }) async {
    if (kIsWeb) {
      final progress = _webProgress.putIfAbsent(planId, () => <int>{});
      if (completed) {
        progress.add(day);
      } else {
        progress.remove(day);
      }
      return;
    }

    final resolvedUserId = await _resolveUserId(userId);
    final db = await _dbHelper!.database;

    if (completed) {
      await db.insert('plan_progreso_usuario', {
        'id_usuario': resolvedUserId,
        'id_plan': planId,
        'dia': day,
        'completado': 1,
        'completado_en': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete(
        'plan_progreso_usuario',
        where: 'id_usuario = ? AND id_plan = ? AND dia = ?',
        whereArgs: [resolvedUserId, planId, day],
      );
    }
  }

  Future<int> _resolveUserId(int? userId) async {
    if (userId != null) {
      return userId;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id') ?? 1;
  }

  ReadingPlan _getWebFallbackPlan(int planId) {
    final fallbackDays = List.generate(
      7,
      (index) => ReadingPlanDay(
        day: index + 1,
        book: 'Juan',
        startChapter: index + 1,
        startVerse: 1,
        endChapter: index + 1,
        endVerse: const [51, 25, 36, 54, 47, 71, 53][index],
        comment: 'Lectura del evangelio de Juan d\u00eda ${index + 1}.',
        completed: _webProgress[planId]?.contains(index + 1) ?? false,
      ),
    );

    return ReadingPlan(
      id: planId,
      name: 'Plan de 7 d\u00edas - Evangelio de Juan',
      description:
          'Una semana explorando los primeros cap\u00edtulos del evangelio de Juan.',
      days: fallbackDays,
    );
  }
}
