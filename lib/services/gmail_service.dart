import 'dart:convert';
import 'package:googleapis/gmail/v1.dart';
import '../models/email_model.dart';
import 'auth_service.dart';

class GmailService {
  final AuthService _authService = AuthService();

  /// Fetches emails from Gmail API
  Future<List<Email>> fetchEmails({int maxResults = 50, String? pageToken}) async {
    try {
      final authClient = await _authService.getGmailAuthClient();
      if (authClient == null) throw Exception('Not authenticated');

      final gmail = GmailApi(authClient);

      // Fetch message list
      final messages = await gmail.users.messages.list(
        'me',
        maxResults: maxResults,
        pageToken: pageToken,
        q: 'in:inbox', // Only fetch inbox emails
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
          // Continue with other emails even if one fails
        }
      }

      return emails;
    } catch (e) {
      print('Gmail Service Error: $e');
      throw Exception('Failed to fetch emails: $e');
    }
  }

  /// Fetches detailed information for a specific email
  Future<Email?> _fetchEmailDetails(GmailApi gmail, String messageId) async {
    try {
      final message = await gmail.users.messages.get(
          'me',
          messageId,
          format: 'full'
      );
      return Email.fromGmailApi(message);
    } catch (e) {
      print('Error fetching email details for $messageId: $e');
      return null;
    }
  }

  /// Fetches the complete email body with full details
  Future<String> getEmailBody(String messageId) async {
    try {
      final authClient = await _authService.getGmailAuthClient();
      if (authClient == null) throw Exception('Not authenticated');

      final gmail = GmailApi(authClient);
      final message = await gmail.users.messages.get(
          'me',
          messageId,
          format: 'full'
      );

      // Use the Email model's body extraction
      return Email.fromGmailApi(message).displayBody;
    } catch (e) {
      print('Error fetching email body for $messageId: $e');
      throw Exception('Failed to fetch email body: $e');
    }
  }

  /// Enhanced method to get complete email with all details
  Future<Email?> getCompleteEmail(String messageId) async {
    try {
      final authClient = await _authService.getGmailAuthClient();
      if (authClient == null) throw Exception('Not authenticated');

      final gmail = GmailApi(authClient);
      final message = await gmail.users.messages.get(
          'me',
          messageId,
          format: 'full'
      );
      return Email.fromGmailApi(message);
    } catch (e) {
      print('Error fetching complete email for $messageId: $e');
      return null;
    }
  }

  /// Fetches emails by label/category
  Future<List<Email>> fetchEmailsByLabel(String label, {int maxResults = 50}) async {
    try {
      final authClient = await _authService.getGmailAuthClient();
      if (authClient == null) throw Exception('Not authenticated');

      final gmail = GmailApi(authClient);
      final messages = await gmail.users.messages.list(
        'me',
        maxResults: maxResults,
        q: 'label:$label',
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
      print('Gmail Service Error for label $label: $e');
      throw Exception('Failed to fetch emails by label: $e');
    }
  }

  /// Marks an email as read
  Future<void> markAsRead(String messageId) async {
    try {
      final authClient = await _authService.getGmailAuthClient();
      if (authClient == null) throw Exception('Not authenticated');

      final gmail = GmailApi(authClient);

      await gmail.users.messages.modify(
        ModifyMessageRequest(
          removeLabelIds: ['UNREAD'],
        ),
        'me',
        messageId,
      );
    } catch (e) {
      print('Error marking email as read: $e');
      throw Exception('Failed to mark email as read');
    }
  }

  /// Marks an email as unread
  Future<void> markAsUnread(String messageId) async {
    try {
      final authClient = await _authService.getGmailAuthClient();
      if (authClient == null) throw Exception('Not authenticated');

      final gmail = GmailApi(authClient);

      await gmail.users.messages.modify(
        ModifyMessageRequest(
          addLabelIds: ['UNREAD'],
        ),
        'me',
        messageId,
      );
    } catch (e) {
      print('Error marking email as unread: $e');
      throw Exception('Failed to mark email as unread');
    }
  }

  /// Searches emails with a query
  Future<List<Email>> searchEmails(String query, {int maxResults = 50}) async {
    try {
      final authClient = await _authService.getGmailAuthClient();
      if (authClient == null) throw Exception('Not authenticated');

      final gmail = GmailApi(authClient);
      final messages = await gmail.users.messages.list(
        'me',
        maxResults: maxResults,
        q: query,
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
      print('Gmail Service Error for search "$query": $e');
      throw Exception('Failed to search emails: $e');
    }
  }

  /// Gets email statistics
  Future<Map<String, dynamic>> getEmailStats() async {
    try {
      final authClient = await _authService.getGmailAuthClient();
      if (authClient == null) throw Exception('Not authenticated');

      final gmail = GmailApi(authClient);

      // Get profile info
      final profile = await gmail.users.getProfile('me');

      // Get some basic stats
      final messages = await gmail.users.messages.list(
        'me',
        maxResults: 1,
      );

      return {
        'emailAddress': profile.emailAddress,
        'messagesTotal': profile.messagesTotal ?? 0,
        'threadsTotal': profile.threadsTotal ?? 0,
        'historyId': profile.historyId ?? 0,
        'recentMessagesCount': messages.messages?.length ?? 0,
      };
    } catch (e) {
      print('Error fetching email stats: $e');
      throw Exception('Failed to fetch email statistics');
    }
  }

  /// Fetches attachments for an email
  Future<List<Map<String, dynamic>>> getAttachments(String messageId) async {
    try {
      final authClient = await _authService.getGmailAuthClient();
      if (authClient == null) throw Exception('Not authenticated');

      final gmail = GmailApi(authClient);
      final message = await gmail.users.messages.get('me', messageId, format: 'full');

      final attachments = <Map<String, dynamic>>[];

      void extractAttachments(MessagePart? part) {
        if (part == null) return;

        // Check if this part is an attachment
        if (part.filename != null && part.filename!.isNotEmpty && part.body?.attachmentId != null) {
          attachments.add({
            'id': part.body!.attachmentId,
            'filename': part.filename,
            'mimeType': part.mimeType,
            'size': part.body!.size,
          });
        }

        // Recursively check subparts
        if (part.parts != null) {
          for (final subPart in part.parts!) {
            extractAttachments(subPart);
          }
        }
      }

      extractAttachments(message.payload);
      return attachments;
    } catch (e) {
      print('Error fetching attachments for $messageId: $e');
      return [];
    }
  }

  /// Downloads a specific attachment
  Future<List<int>> downloadAttachment(String messageId, String attachmentId) async {
    try {
      final authClient = await _authService.getGmailAuthClient();
      if (authClient == null) throw Exception('Not authenticated');

      final gmail = GmailApi(authClient);
      final attachment = await gmail.users.messages.attachments.get('me', messageId, attachmentId);

      if (attachment.data != null) {
        // Decode base64 attachment data
        final decodedData = base64.decode(attachment.data!);
        return decodedData;
      }

      throw Exception('No attachment data found');
    } catch (e) {
      print('Error downloading attachment: $e');
      throw Exception('Failed to download attachment: $e');
    }
  }
}