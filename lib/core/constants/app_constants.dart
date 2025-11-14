class AppConstants {
  // App Info
  static const String appName = 'Maika';
  static const String appSubtitle = 'Tu asistente bíblico personal';
  static const String appVersion = '1.0.0';

  // Colors
  static const int primaryColor = 0xFF6750A4;
  static const int secondaryColor = 0xFF625B71;
  static const int tertiaryColor = 0xFF7D5260;
  static const int backgroundColor = 0xFFFEF7FF;
  static const int surfaceColor = 0xFFFFFBFE;

  // API URLs
  static const String rasaWebhookUrl =
      'http://localhost:5005/webhooks/rest/webhook';
  static const String baseApiUrl = 'https://api.maika.com';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Text Styles
  static const double titleFontSize = 24.0;
  static const double subtitleFontSize = 18.0;
  static const double bodyFontSize = 16.0;
  static const double captionFontSize = 14.0;

  // Spacing
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;

  // Border Radius
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 24.0;

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String chatHistoryKey = 'chat_history';
  static const String favoritesKey = 'favorites';
}
