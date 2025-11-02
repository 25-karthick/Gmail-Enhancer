import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  Future<String> summarizeEmail({
    required String subject,
    required String emailContent,
  }) async {
    try {
      final truncatedContent = _truncateEmailContent(emailContent);
      print("🚀 Summarizing with Gemini...");

      final prompt = '''
Please analyze this email and provide a concise 2-3 sentence summary.
EMAIL SUBJECT: $subject
EMAIL PREVIEW:
$truncatedContent
Provide a summary focusing on:
1. The main purpose or key message
2. Any important actions or deadlines
3. The overall intent
Summary:
''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=${Env.geminiApiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts": [{"text": prompt}]}],
          "generationConfig": {
            "maxOutputTokens": 800,
            "temperature": 0.3,
            "topP": 0.8,
            "topK": 40,
          },
          "safetySettings": [
            {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
            {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
            {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
            {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"}
          ]
        }),
      );

      return _parseGeminiResponse(response);

    } catch (e) {
      print('❌ GeminiService Network or Other Error: $e');
      return 'Summary unavailable due to a network error.';
    }
  }

  String _truncateEmailContent(String content, {int maxLines = 15, int maxLength = 800}) {
    if (content.isEmpty) return 'No content available';
    final lines = content.split('\n');
    final truncatedLines = lines.take(maxLines).where((line) => line.trim().isNotEmpty).toList();
    String truncated = truncatedLines.join('\n');
    if (truncated.length > maxLength) {
      truncated = truncated.substring(0, maxLength) + '...';
    }
    return truncated;
  }

  String _parseGeminiResponse(http.Response response) {
    if (response.statusCode != 200) {
      print('❌ Gemini API Error: Received HTTP Status ${response.statusCode}');
      print('   - Response Body: ${response.body}');
      return 'Summary unavailable (API Error ${response.statusCode})';
    }

    try {
      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        final error = data['error'];
        print('❌ Gemini API Error Payload: ${error['message']}');
        return 'Summary unavailable (API Error)';
      }

      final candidates = data['candidates'];
      if (candidates != null && candidates.isNotEmpty) {
        final finishReason = candidates[0]['finishReason'];

        // ✅ IMPROVED LOGIC: Check for safety blocks first
        if (finishReason == 'SAFETY') {
          print('⚠️ Gemini API Block: Finish reason is "SAFETY".');
          return 'Summary blocked by safety settings.';
        }

        final content = candidates[0]['content'];
        if (content != null && content['parts'] != null && content['parts'].isNotEmpty) {
          final text = content['parts'][0]['text'];
          if (text != null && text.toString().trim().isNotEmpty) {
            print("✅ Summary generated successfully!");
            if (finishReason == 'MAX_TOKENS') {
              print("⚠️ Warning: Summary may be truncated (MAX_TOKENS).");
            }
            return text.toString().trim();
          }
        }
      }

      print('⚠️ Gemini Warning: API response was valid but contained no summary text.');
      return 'Summary not available (Empty response).';

    } catch (e) {
      print('❌ Gemini Error: Failed to parse API response. $e');
      return 'Summary unavailable (Invalid response format).';
    }
  }
}