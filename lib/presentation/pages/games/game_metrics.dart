const String maikaFragmentadaGameKey = 'maika_fragmentada';

String normalizeTrackedGameKey(String rawKey) {
  final trimmed = rawKey.trim();
  if (trimmed.isEmpty) {
    return 'unknown';
  }

  switch (trimmed.toLowerCase()) {
    case maikaFragmentadaGameKey:
    case 'maika y la biblia fragmentada':
      return maikaFragmentadaGameKey;
    default:
      return trimmed;
  }
}

String trackedGameTitle(String rawKey) {
  switch (normalizeTrackedGameKey(rawKey)) {
    case maikaFragmentadaGameKey:
      return 'Maika y la Biblia Fragmentada';
    default:
      return rawKey.trim().isEmpty ? 'Juego desconocido' : rawKey.trim();
  }
}
