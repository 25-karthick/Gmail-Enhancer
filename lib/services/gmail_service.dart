import 'dart:async';
import 'package:googleapis/gmail/v1.dart';
import '../models/email_model.dart';
import 'auth_service.dart';

class GmailService {
  final AuthService _authService = AuthService();

  /// A private helper to get an authenticated Gmail API client.
  Future<GmailApi> _getGmailApi() async {
    final authClient = await _authService.getGmailAuthClient();
    if (authClient == null) {
      throw Exception('Authentication failed: No authenticated client.');
    }
    return GmailApi(authClient);
  }

  /// Fetches a list of emails from the user's inbox.
  /// ✅ This version runs all detail requests in parallel for maximum speed.
  Future<List<Email>> fetchEmails({int maxResults = 50, String? pageToken}) async {
    try {
      final gmail = await _getGmailApi();

      final messageList = await gmail.users.messages.list(
        'me',
        maxResults: maxResults,
        pageToken: pageToken,
        q: 'in:inbox',
      );

      if (messageList.messages == null || messageList.messages!.isEmpty) {
        return [];
      }

      // 2. Create a list of future requests
      final emailFutures = messageList.messages!.map((message) {
        return _fetchEmailDetails(gmail, message.id!);
      }).toList();

      // 3. Execute all requests concurrently
      final resolvedEmails = await Future.wait(emailFutures);

      // 4. Filter out any nulls
      return resolvedEmails.whereType<Email>().toList();
    } catch (e) {
      print('Gmail Service Error: $e');
      throw Exception('Failed to fetch emails: $e');
    }
  }

  /// Fetches detailed information for a single email.
  Future<Email?> _fetchEmailDetails(GmailApi gmail, String messageId) async {
    try {
      final message = await gmail.users.messages.get('me', messageId, format: 'full');
      return Email.fromGmailApi(message);
    } catch (e) {
      print('Error fetching email details for $messageId: $e');
      return null;
    }
  }

  /// Fetches a single, complete email object.
  Future<Email?> getCompleteEmail(String messageId) async {
    try {
      final gmail = await _getGmailApi();
      return await _fetchEmailDetails(gmail, messageId);
    } catch (e) {
      print('Error fetching complete email for $messageId: $e');
      return null;
    }
  }

  /// A generic method to modify an email's labels.
  Future<void> _modifyEmailLabels(String messageId, List<String>? addLabelIds, List<String>? removeLabelIds) async {
    try {
      final gmail = await _getGmailApi();
      await gmail.users.messages.modify(
        ModifyMessageRequest(
          addLabelIds: addLabelIds,
          removeLabelIds: removeLabelIds,
        ),
        'me',
        messageId,
      );
    } catch (e) {
      print('Error modifying labels for email $messageId: $e');
      throw Exception('Failed to modify email labels.');
    }
  }

  Future<void> markAsRead(String messageId) async {
    await _modifyEmailLabels(messageId, null, ['UNREAD']);
  }

  Future<void> markAsUnread(String messageId) async {
    await _modifyEmailLabels(messageId, ['UNREAD'], null);
  }
}
