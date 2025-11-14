// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../config/download_config.dart';

Future<void> triggerWebDownload(String url, {String? filename}) async {
  final String? proxy = audioProxyBaseUrl;

  final String effectiveUrl = proxy == null || proxy.isEmpty
      ? url
      : '$proxy?url=' + Uri.encodeComponent(url);

  try {
    // Try to fetch as Blob first (best UX when CORS allows it)
    final req = await html.HttpRequest.request(
      effectiveUrl,
      method: 'GET',
      responseType: 'blob',
      withCredentials: false,
    );
    final blob = req.response as html.Blob;
    final objectUrl = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: objectUrl)
      ..download = filename ?? 'audio.mp3';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(objectUrl);
    return;
  } catch (_) {
    // CORS blocked. Fallback: navigate to the URL with download attribute.
    // Some browsers may still open a new tab, but it avoids CORS entirely.
    try {
    final anchor = html.AnchorElement(href: effectiveUrl)
      ..download = filename ?? 'audio.mp3'
      ..rel = 'noopener'
      ..target = '_blank';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
    } catch (_) {
      // Last resort: open in a new tab; user can Save As from the browser
    html.window.open(effectiveUrl, '_blank');
    }
  }
}

// For symmetry with IO helper
Future<void> pickAndSaveAudioFromUrl(String url, {required String filename}) async {
  await triggerWebDownload(url, filename: filename);
}


