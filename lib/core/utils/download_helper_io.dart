import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:http/http.dart' as http;

Future<void> pickAndSaveAudioFromUrl(String url, {required String filename}) async {
  // Download bytes
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception('No se pudo descargar el archivo (HTTP ${response.statusCode}).');
  }
  final bytes = Uint8List.fromList(response.bodyBytes);

  // Use FileSaver to present a save dialog on Android and desktop
  await FileSaver.instance.saveFile(
    name: filename,
    bytes: bytes,
    ext: 'mp3',
    // Use generic type; mp3 will be inferred by extension
    mimeType: MimeType.other,
  );
}

// For symmetry with web helper (unused on IO)
Future<void> triggerWebDownload(String url, {String? filename}) async {}


