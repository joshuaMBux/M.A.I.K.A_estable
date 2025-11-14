import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class AudioSyncService {
  final DatabaseHelper _dbHelper;
  static const String baseUrl = AppConstants.baseApiUrl;

  AudioSyncService(this._dbHelper);

  /// Fetches metadata for all audio chapters from the API Gateway
  /// Expected endpoint: /api/v1/audio/metadata?version={rv1960}
  Future<void> syncMetadata({String version = 'rv1960'}) async {
    try {
      developer.log('Starting audio metadata sync for version: $version', name: 'AudioSyncService');

      final url = '$baseUrl/api/v1/audio/metadata?version=$version';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> metadataList = data['metadata'] as List<dynamic>;

        await _persistMetadata(metadataList);
        developer.log('Audio metadata sync completed. Processed ${metadataList.length} chapters.', name: 'AudioSyncService');
      } else {
        throw Exception('Failed to fetch metadata: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      developer.log('Error syncing audio metadata: $e', name: 'AudioSyncService', error: e);
      rethrow;
    }
  }

  /// Persists metadata to the local SQLite database
  Future<void> _persistMetadata(List<dynamic> metadataList) async {
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      for (final item in metadataList) {
        final map = item as Map<String, dynamic>;
        
        // Check if record exists
        final existing = await txn.query(
          'audio_capitulo',
          where: 'id_libro = ? AND capitulo = ?',
          whereArgs: [map['id_libro'], map['capitulo']],
          limit: 1,
        );

        final audioData = {
          'id_libro': map['id_libro'],
          'capitulo': map['capitulo'],
          'url': map['url'],
          'duracion_segundos': map['duracion_segundos'],
          'file_size_bytes': map['file_size_bytes'],
          'checksum_hash': map['checksum_hash'],
        };

        if (existing.isEmpty) {
          // Insert new record with default REMOTE status
          audioData['download_status'] = 'REMOTE';
          await txn.insert('audio_capitulo', audioData);
        } else {
          // Update existing record but preserve download_status and local_path
          final existingData = existing.first;
          audioData['id_audio'] = existingData['id_audio'];
          audioData['download_status'] = existingData['download_status'];
          audioData['local_path'] = existingData['local_path'];
          
          await txn.update(
            'audio_capitulo',
            audioData,
            where: 'id_audio = ?',
            whereArgs: [existingData['id_audio']],
          );
        }
      }
    });
  }

  /// Check if metadata needs to be synced (useful for periodic sync)
  Future<bool> needsSync() async {
    final db = await _dbHelper.database;
    final count = sqflite.Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM audio_capitulo WHERE url IS NULL OR file_size_bytes IS NULL'),
    ) ?? 0;
    return count > 0;
  }
}

