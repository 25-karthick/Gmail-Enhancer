import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart'; // Ensure you have this file with Env.geminiApiKey

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Summarize email using only subject and first few lines for efficiency
  ///
  /// [FIXED]: The method signature now correctly uses only named arguments.
  Future<String> summarizeEmail({
    required String subject,
    required String emailContent,
  }) async {
    try {
      // Extract first few lines of content (more efficient)
      final truncatedContent = _truncateEmailContent(emailContent);

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
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": prompt
                }
              ]
            }
          ],
          "generationConfig": {
            "maxOutputTokens": 200, // Reduced for shorter summaries
            "temperature": 0.3,
            "topP": 0.8,
            "topK": 40,
          },
          "safetySettings": [
            {
              "category": "HARM_CATEGORY_HARASSMENT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_HATE_SPEECH",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            },
            {
              "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE"
            }
          ]
        }),
      );

      return _parseGeminiResponse(response);
    } catch (e) {
      print('❌ GeminiService Error: $e');
      return 'Summary unavailable.';
    }
  }

  /// Truncate email content to first few lines (more efficient)
  String _truncateEmailContent(String content, {int maxLines = 10, int maxLength = 500}) {
    if (content.isEmpty) return 'No content available';

    // Split into lines and take first few
    final lines = content.split('\n');
    final truncatedLines = lines.take(maxLines).where((line) => line.trim().isNotEmpty).toList();

    // Join and limit total length
    String truncated = truncatedLines.join('\n');
    if (truncated.length > maxLength) {
      truncated = truncated.substring(0, maxLength) + '...';
    }

    return truncated;
  }

  /// Quick summary for list view (even more minimal)
  Future<String> generateQuickSummary(String subject, String preview) async {
    try {
      final prompt = '''
Provide a one-sentence summary of this email:

Subject: $subject
Preview: ${preview.length > 100 ? preview.substring(0, 100) + '...' : preview}

One-sentence summary:
''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=${Env.geminiApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": prompt
                }
              ]
            }
          ],
          "generationConfig": {
            "maxOutputTokens": 80, // Very short for one sentence
            "temperature": 0.2,
            "topP": 0.8,
          }
        }),
      );

      final summary = _parseGeminiResponse(response);
      return summary.length > 120 ? '${summary.substring(0, 117)}...' : summary;
    } catch (e) {
      print('❌ Quick summary error: $e');
      return 'Quick summary not available.';
    }
  }

  /// Parse Gemini API response
  String _parseGeminiResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final candidates = data['candidates'];
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        if (content is Map && content['parts'] != null) {
          final parts = content['parts'];
          if (parts is List && parts.isNotEmpty) {
            final text = parts[0]['text'];
            if (text != null) {
              final summary = text.toString().trim();
              if (summary.isNotEmpty) {
                print("✅ Summary generated successfully");
                return summary;
              }
            }
          }
        }
      }

      // Check for errors in response
      if (data['error'] != null) {
        final error = data['error'];
        print('❌ Gemini API Error: ${error['message']}');
        throw Exception('API Error: ${error['message']}');
      }

      return 'Summary not available.';
    } else {
      print('❌ HTTP Error: ${response.statusCode} - ${response.body}');
      throw Exception('API request failed with status ${response.statusCode}');
    }
  }

  /// Clean and format the summary
  /// This robust version handles bolding, quotes, and all types of whitespace/newlines.


  /// Batch summarize multiple emails efficiently
  Future<Map<String, String>> summarizeEmailsBatch(Map<String, Map<String, String>> emailData) async {
    final summaries = <String, String>{};
    int processed = 0;

    for (final entry in emailData.entries) {
      final emailId = entry.key;
      final data = entry.value;

      try {
        final summary = await summarizeEmail(
          subject: data['subject'] ?? '',
          emailContent: data['content'] ?? '',
        );

        summaries[emailId] = summary;
        processed++;

        // Shorter delay between requests
        if (processed < emailData.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        print('❌ Failed to summarize email $emailId: $e');
        summaries[emailId] = 'Summary unavailable.';
      }
    }

    return summaries;
  }

  /// Check if Gemini API is accessible
  Future<bool> checkApiAvailability() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=${Env.geminiApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": "Respond with 'OK'"
                }
              ]
            }
          ],
          "generationConfig": {
            "maxOutputTokens": 5,
            "temperature": 0.1,
          }
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ API availability check failed: $e');
      return false;
    }
  }

  /// Get content preview for email (first few meaningful lines)
  String getEmailPreview(String content) {
    if (content.isEmpty) return 'No content';

    // Remove excessive whitespace and get meaningful lines
    final lines = content.split('\n')
        .where((line) => line.trim().isNotEmpty)
        .where((line) => line.length > 10) // Filter out very short lines
        .take(5) // Take first 5 meaningful lines
        .toList();

    if (lines.isEmpty) {
      return content.length > 100 ? content.substring(0, 100) + '...' : content;
    }

    final preview = lines.join(' ');
    return preview.length > 150 ? preview.substring(0, 147) + '...' : preview;
  }
}