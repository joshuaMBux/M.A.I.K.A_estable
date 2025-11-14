String formatRelativeTime(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inSeconds < 60) {
    return 'hace unos segundos';
  }
  if (difference.inMinutes == 1) {
    return 'hace 1 minuto';
  }
  if (difference.inMinutes < 60) {
    return 'hace ${difference.inMinutes} minutos';
  }
  if (difference.inHours == 1) {
    return 'hace 1 hora';
  }
  if (difference.inHours < 24) {
    return 'hace ${difference.inHours} horas';
  }
  if (difference.inDays == 1) {
    return 'hace 1 dia';
  }
  if (difference.inDays < 7) {
    return 'hace ${difference.inDays} dias';
  }

  final weeks = (difference.inDays / 7).floor();
  if (weeks == 1) {
    return 'hace 1 semana';
  }
  if (weeks < 5) {
    return 'hace $weeks semanas';
  }

  final months = (difference.inDays / 30).floor();
  if (months == 1) {
    return 'hace 1 mes';
  }
  if (months < 12) {
    return 'hace $months meses';
  }

  final years = (difference.inDays / 365).floor();
  if (years <= 1) {
    return 'hace 1 anio';
  }
  return 'hace $years anios';
}
