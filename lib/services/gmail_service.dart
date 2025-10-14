import 'dart:convert';
import "../providers/email_provider.dart";
import 'package:googleapis/gmail/v1.dart';
import '../models/email_model.dart';
import 'auth_service.dart';

class GmailService {
  final AuthService _authService = AuthService();

  Future<List<Email>> fetchEmails({int maxResults = 50}) async {
    try {
      final authClient = await _authService.getGmailAuthClient();
      if (authClient == null) throw Exception('Not authenticated');

      final gmail = GmailApi(authClient);
      final messages = await gmail.users.messages.list(
        'me',
        maxResults: maxResults,
      );

      if (messages.messages == null) return [];

      final emails = <Email>[];
      for (final message in messages.messages!) {
        try {
          final email = await _fetchEmailDetails(gmail, message.id!);
          if (email != null) {
            emails.add(email);
          }
        } catch (e) {
          print('Error fetching email ${message.id}: $e');
        }
      }

      return emails;
    } catch (e) {
      print('Gmail Service Error: $e');
      throw Exception('Failed to fetch emails: $e');
    }
  }

  Future<Email?> _fetchEmailDetails(GmailApi gmail, String messageId) async {
    try {
      final message = await gmail.users.messages.get('me', messageId,format: 'full');
      return Email.fromGmailApi(message);
    } catch (e) {
      print('Error fetching email details: $e');
      return null;
    }
  }

  Future<String> getEmailBody(String messageId) async {
    try {
      final authClient = await _authService.getGmailAuthClient();
      if (authClient == null) throw Exception('Not authenticated');

      final gmail = GmailApi(authClient);
      final message = await gmail.users.messages.get('me', messageId);

      // Extract body from message payload
      return _extractBody(message);
    } catch (e) {
      print('Error fetching email body: $e');
      throw Exception('Failed to fetch email body');
    }
  }

  String _extractBody(Message message) {
    // Implement body extraction logic from Gmail API response
    // This is a simplified version - you'll need to handle different payload structures
    if (message.payload?.body?.data != null) {
      return _decodeBase64(message.payload!.body!.data!);
    }

    if (message.payload?.parts != null) {
      for (final part in message.payload!.parts!) {
        if (part.mimeType == 'text/plain' && part.body?.data != null) {
          return _decodeBase64(part.body!.data!);
        }
      }
    }

    return message.snippet ?? '';
  }

  String _decodeBase64(String data) {
    try {
      // Gmail API uses URL-safe base64 encoding
      final normalizedData = data.replaceAll('-', '+').replaceAll('_', '/');
      return utf8.decode(base64.decode(normalizedData));
    } catch (e) {
      return data;
    }
  }
}