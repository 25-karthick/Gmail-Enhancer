class AppConstants {
  static const String appName = 'Gmail Summarizer';
  static const String appVersion = '1.0.0';

  // API Constants
  static const int maxEmailFetchLimit = 50;
  static const int summaryMaxTokens = 100;

  // Storage Keys
  static const String prefUserEmail = 'user_email';
  static const String prefLastSync = 'last_sync';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
}

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String emailDetail = '/email-detail';
  static const String settings = '/settings';
}