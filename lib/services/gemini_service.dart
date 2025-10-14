import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Split text into chunks of ~maxChars characters
  List<String> _splitIntoChunks(String text, {int maxChars = 1000}) {
    final chunks = <String>[];
    int start = 0;

    while (start < text.length) {
      final end = (start + maxChars < text.length) ? start + maxChars : text.length;
      chunks.add(text.substring(start, end));
      start = end;
    }

    return chunks;
  }

  /// Summarize a single chunk safely
  Future<String> _summarizeChunk(String chunk) async {
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
                  "text":
                  "Summarize this chunk in one concise sentence focusing on key actions or important info:\n$chunk"
                }
              ]
            }
          ],
          "generationConfig": {
            "maxOutputTokens": 100,
            "temperature": 0.2,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Gemini raw response: $data');

        final candidates = data['candidates'];
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          if (content is Map && content['parts'] != null) {
            final parts = content['parts'];
            if (parts is List && parts.isNotEmpty) {
              final text = parts[0]['text'];
              if (text != null && text.toString().trim().isNotEmpty) {
                return text.toString().trim();
              }
            }
          }
        }

        return 'Summary unavailable (chunk had no content).';
      } else {
        throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('GeminiService Error (chunk): $e');
      return 'Failed to generate summary';
    }
  }

  /// Summarize very long email by chunking and merging summaries
  Future<String> summarizeEmail(String emailContent) async {
    final chunks = _splitIntoChunks(emailContent, maxChars: 1000);
    final chunkSummaries = <String>[];

    for (final chunk in chunks) {
      final summary = await _summarizeChunk(chunk);
      chunkSummaries.add(summary);

      // Small delay to avoid hitting rate limits
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Merge all chunk summaries into one final concise sentence
    final mergedPrompt = chunkSummaries.join(' ');

    // Final summary using Gemini on merged text
    return await _summarizeChunk(
      "Combine these summaries into a single concise sentence:\n$mergedPrompt",
    );
  }

  /// Batch summarize multiple emails
  Future<Map<String, String>> summarizeEmails(Map<String, String> emailContents) async {
    final summaries = <String, String>{};

    for (final entry in emailContents.entries) {
      final key = entry.key;
      final content = entry.value;

      try {
        final summary = await summarizeEmail(content);
        summaries[key] = summary;

        await Future.delayed(const Duration(seconds: 1)); // rate limit safety
      } catch (e) {
        summaries[key] = 'Failed to generate summary';
      }
    }

    return summaries;
  }
}
