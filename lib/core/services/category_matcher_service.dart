class CategoryMatcherService {
  static const Map<String, List<String>> _keywordsByCategory = {
    'Amor': ['amor', 'amo', 'amó', 'amados', 'amar'],
    'Fe': ['fe', 'creer', 'cree', 'creo', 'confianza'],
    'Esperanza': ['esperanza', 'esperar', 'esperen', 'esperamos'],
    'Paz': ['paz', 'reposo', 'tranquilidad'],
    'Perdón': ['perdon', 'perdón', 'perdonar', 'perdona', 'perdonados'],
    'Gratitud': ['gracias', 'gratitud', 'agradecido', 'agradecer'],
  };

  /// Devuelve la lista de nombres de categoría que coinciden
  /// con el [texto] dado, usando coincidencias case-insensitive
  /// sobre las palabras clave configuradas.
  List<String> matchCategories(String texto) {
    if (texto.trim().isEmpty) return const [];

    final lower = texto.toLowerCase();
    final matched = <String>[];

    _keywordsByCategory.forEach((category, keywords) {
      for (final keyword in keywords) {
        if (keyword.isEmpty) continue;
        if (lower.contains(keyword.toLowerCase())) {
          matched.add(category);
          break;
        }
      }
    });

    return matched;
  }
}

