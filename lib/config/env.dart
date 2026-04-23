import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get geminiApiKey => dotenv.get('GEMINI_API_KEY');
  static String get gmailClientId => dotenv.get('GMAIL_CLIENT_ID');
  
  static String get firebaseWebApi => dotenv.get('FIREBASE_WEB_API_KEY');
  static String get firebaseWebAppId => dotenv.get('FIREBASE_WEB_APP_ID');

  static String get firebaseAndroidApi => dotenv.get('FIREBASE_ANDROID_API_KEY');
  static String get firebaseAndroidAppId => dotenv.get('FIREBASE_ANDROID_APP_ID');

  static String get firebaseWindowsApi => dotenv.get('FIREBASE_WINDOWS_API_KEY');
  static String get firebaseWindowsAppId => dotenv.get('FIREBASE_WINDOWS_APP_ID');
}