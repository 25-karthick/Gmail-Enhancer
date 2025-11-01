import 'dart:convert';
import 'package:googleapis/gmail/v1.dart';
import 'package:html_unescape/html_unescape.dart';

class Email {
  final String id;
  final String subject;
  final String sender;
  final String senderEmail;
  final DateTime date;
  final String snippet;
  final String? body;
  final String category;
  final String? summary;
  final bool isRead;
  final bool hasAttachment;
  final List<String> cc;
  final List<String> bcc;
  final String? fullBody;

  Email({
    required this.id,
    required this.subject,
    required this.sender,
    required this.senderEmail,
    required this.date,
    required this.snippet,
    this.body,
    this.category = 'General',
    this.summary,
    this.isRead = false,
    this.hasAttachment = false,
    this.cc = const [],
    this.bcc = const [],
    this.fullBody,
  });

  factory Email.fromGmailApi(Message message) {
    final MessagePart? payload = message.payload;
    final List<MessagePartHeader> headers = payload?.headers ?? [];

    // Helper function to safely find header values
    String findHeaderValue(String name) {
      final header = headers.firstWhere(
            (h) => h.name?.toLowerCase() == name.toLowerCase(),
        orElse: () => MessagePartHeader(),
      );
      return header.value ?? '';
    }

    // Helper function to extract email lists from headers
    List<String> extractEmailList(String headerValue) {
      if (headerValue.isEmpty) return [];
      return headerValue.split(',').map((email) => email.trim()).where((email) => email.isNotEmpty).toList();
    }

    final String fromHeader = findHeaderValue('From');
    final String subject = findHeaderValue('Subject').isEmpty ? '(No Subject)' : findHeaderValue('Subject');
    final String ccHeader = findHeaderValue('Cc');
    final String bccHeader = findHeaderValue('Bcc');

    // Check for attachments
    bool hasAttachment = _checkForAttachments(message.payload);

    // Extract full body with improved parsing
    final String fullBody = _extractReadableBody(message);

    return Email(
      id: message.id!,
      subject: subject,
      sender: _extractSenderName(fromHeader),
      senderEmail: _extractSenderEmail(fromHeader),
      date: DateTime.fromMillisecondsSinceEpoch(
          int.parse(message.internalDate!),
          isUtc: true
      ).toLocal(),
      snippet: message.snippet ?? '',
      isRead: !(message.labelIds?.contains('UNREAD') ?? false),
      hasAttachment: hasAttachment,
      cc: extractEmailList(ccHeader),
      bcc: extractEmailList(bccHeader),
      fullBody: fullBody,
      body: fullBody,
    );
  }

  static bool _checkForAttachments(MessagePart? part) {
    if (part == null) return false;

    // Check if this part has attachment data
    if (part.body?.attachmentId != null) {
      return true;
    }

    // Check if any subpart has attachments
    if (part.parts != null) {
      for (final subPart in part.parts!) {
        if (_checkForAttachments(subPart)) {
          return true;
        }
      }
    }

    return false;
  }

  static String _extractReadableBody(Message message) {
    try {
      // Try plain text first
      String? plainText = _extractPlainText(message.payload);
      if (plainText != null && plainText.isNotEmpty) {
        return _cleanText(plainText);
      }

      // Try HTML conversion
      String? htmlBody = _extractHtmlBody(message.payload);
      if (htmlBody != null && htmlBody.isNotEmpty) {
        return _convertHtmlToPlainText(htmlBody);
      }

      // Fallback to snippet
      return message.snippet ?? 'No content available';
    } catch (e) {
      print('Error extracting readable body: $e');
      return message.snippet ?? 'Failed to load email content';
    }
  }

  static String? _extractPlainText(MessagePart? part) {
    if (part == null) return null;

    // Check if this part is plain text
    if (part.mimeType == 'text/plain' && part.body?.data != null) {
      return _decodeBase64(part.body!.data!);
    }

    // Recursively check parts
    if (part.parts != null) {
      // First, look for plain text parts
      for (final subPart in part.parts!) {
        if (subPart.mimeType == 'text/plain') {
          final text = _extractPlainText(subPart);
          if (text != null && text.isNotEmpty) return text;
        }
      }

      // If no plain text found, try any text part
      for (final subPart in part.parts!) {
        final text = _extractPlainText(subPart);
        if (text != null && text.isNotEmpty) return text;
      }
    }

    return null;
  }

  static String? _extractHtmlBody(MessagePart? part) {
    if (part == null) return null;

    // Check if this part is HTML
    if (part.mimeType == 'text/html' && part.body?.data != null) {
      return _decodeBase64(part.body!.data!);
    }

    // Recursively check parts
    if (part.parts != null) {
      for (final subPart in part.parts!) {
        if (subPart.mimeType == 'text/html') {
          final html = _extractHtmlBody(subPart);
          if (html != null && html.isNotEmpty) return html;
        }
      }
    }

    return null;
  }

  static String _convertHtmlToPlainText(String html) {
    try {
      final HtmlUnescape htmlUnescape = HtmlUnescape();

      // Remove HTML tags and decode HTML entities
      String text = html
          .replaceAll(RegExp(r'<head>.*?</head>', caseSensitive: false), '') // Remove head
          .replaceAll(RegExp(r'<style>.*?</style>', caseSensitive: false), '') // Remove styles
          .replaceAll(RegExp(r'<script>.*?</script>', caseSensitive: false), '') // Remove scripts
          .replaceAll(RegExp(r'<[^>]*>'), ' ') // Remove remaining HTML tags
          .replaceAll(RegExp(r'\s+'), ' ') // Collapse multiple spaces
          .replaceAll(RegExp(r'&nbsp;'), ' ') // Replace non-breaking spaces
          .trim();

      // Unescape HTML entities
      text = htmlUnescape.convert(text);

      return _cleanText(text);
    } catch (e) {
      print('Error converting HTML to plain text: $e');
      return 'Content preview not available';
    }
  }

  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Normalize line breaks
        .replaceAll(RegExp(r'[ \t]+'), ' ') // Collapse multiple spaces/tabs
        .replaceAll(RegExp(r'^\s+', multiLine: true), '') // Remove leading spaces from lines
        .replaceAll(RegExp(r'\s+$', multiLine: true), '') // Remove trailing spaces from lines
        .trim();
  }

  static String _decodeBase64(String data) {
    try {
      if (data.isEmpty) return '';

      // Handle URL-safe base64 encoding used by Gmail
      String normalizedData = data.replaceAll('-', '+').replaceAll('_', '/');

      // Add padding if needed
      final mod = normalizedData.length % 4;
      if (mod != 0) {
        normalizedData += '=' * (4 - mod);
      }

      final decodedBytes = base64.decode(normalizedData);
      return utf8.decode(decodedBytes);
    } catch (e) {
      print('Base64 decoding error for data: ${data.length} chars. Error: $e');
      return 'Failed to decode content';
    }
  }

  static String _extractSenderName(String from) {
    try {
      // Handle formats like: "John Doe <john@example.com>" or "john@example.com"
      final regex = RegExp(r'"?(.+?)"?\s*<(.+?)>');
      final match = regex.firstMatch(from);
      if (match != null) {
        return match.group(1)!.trim();
      }

      // If no angle brackets, return the whole string
      return from.trim();
    } catch (e) {
      return from;
    }
  }

  static String _extractSenderEmail(String from) {
    try {
      // Extract email from format: "John Doe <john@example.com>"
      final regex = RegExp(r'<(.+?)>');
      final match = regex.firstMatch(from);
      if (match != null) {
        return match.group(1)!.trim();
      }

      // If no angle brackets, assume the whole string is the email
      return from.trim();
    } catch (e) {
      return from;
    }
  }

  Email copyWith({
    String? summary,
    String? category,
    bool? isRead,
    String? fullBody,
    List<String>? cc,
    List<String>? bcc,
    bool? hasAttachment,
  }) {
    return Email(
      id: id,
      subject: subject,
      sender: sender,
      senderEmail: senderEmail,
      date: date,
      snippet: snippet,
      body: body,
      category: category ?? this.category,
      summary: summary ?? this.summary,
      isRead: isRead ?? this.isRead,
      hasAttachment: hasAttachment ?? this.hasAttachment,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      fullBody: fullBody ?? this.fullBody,
    );
  }

  @override
  String toString() {
    return 'Email{id: $id, subject: $subject, sender: $sender, category: $category, date: $date}';
  }

  // Helper method to check if email has valid content
  bool get hasValidContent {
    return (fullBody?.isNotEmpty == true) ||
        (body?.isNotEmpty == true) ||
        (snippet.isNotEmpty && snippet != 'No content available');
  }

  // Get display body - prefers fullBody, falls back to body, then snippet
  String get displayBody {
    return fullBody ?? body ?? snippet;
  }
}