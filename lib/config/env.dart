import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get geminiApiKey => dotenv.get('GEMINI_API_KEY');
  static String get gmailClientId => dotenv.get('GMAIL_CLIENT_ID');
}