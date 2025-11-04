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

  /// This is the clean, plain-text content for the AI
  final String? body;

  /// This is the raw HTML content for the WebView
  final String? htmlBody;

  final String category;
  final String? summary;
  final bool isRead;
  final bool hasAttachment;
  final List<String> cc;
  final List<String> bcc;

  Email({
    required this.id,
    required this.subject,
    required this.sender,
    required this.senderEmail,
    required this.date,
    required this.snippet,
    this.body,
    this.htmlBody, // Added
    this.category = 'General',
    this.summary,
    this.isRead = false,
    this.hasAttachment = false,
    this.cc = const [],
    this.bcc = const [],
  });

  factory Email.fromGmailApi(Message message) {
    final payload = message.payload;
    final headers = payload?.headers ?? [];

    String findHeaderValue(String name) {
      return headers.firstWhere((h) => h.name?.toLowerCase() == name.toLowerCase(), orElse: () => MessagePartHeader()).value ?? '';
    }
    List<String> extractEmailList(String headerValue) {
      if (headerValue.isEmpty) return [];
      return headerValue.split(',').map((email) => email.trim()).where((email) => email.isNotEmpty).toList();
    }

    // New, robust parsing logic
    final htmlPart = _findPartByMimeType(payload, 'text/html');
    final plainTextPart = _findPartByMimeType(payload, 'text/plain');

    String? htmlContent = (htmlPart?.body?.data != null) ? _decodeBase64(htmlPart!.body!.data!) : null;
    String? plainTextContent = (plainTextPart?.body?.data != null) ? _decodeBase64(plainTextPart!.body!.data!) : null;

    // Create fallback logic
    if (plainTextContent == null && htmlContent != null) {
      plainTextContent = _convertHtmlToPlainText(htmlContent);
    }
    plainTextContent ??= message.snippet;

    return Email(
      id: message.id!,
      subject: findHeaderValue('Subject').isEmpty ? '(No Subject)' : findHeaderValue('Subject'),
      sender: _extractSenderName(findHeaderValue('From')),
      senderEmail: _extractSenderEmail(findHeaderValue('From')),
      date: DateTime.fromMillisecondsSinceEpoch(int.parse(message.internalDate!), isUtc: true).toLocal(),
      snippet: message.snippet ?? '',
      isRead: !(message.labelIds?.contains('UNREAD') ?? false),
      hasAttachment: _checkForAttachments(payload),
      cc: extractEmailList(findHeaderValue('Cc')),
      bcc: extractEmailList(findHeaderValue('Bcc')),

      body: plainTextContent, // Assign the clean text
      htmlBody: htmlContent, // Assign the raw HTML
    );
  }

  // --- New Getters for easy access ---

  String get plainTextBodyForAI {
    return body ?? snippet;
  }

  String get displayBodyForWebView {
    return htmlBody ?? '<body><p>${body ?? snippet}</p></body>';
  }

  bool get hasValidContent {
    final text = (body ?? '').trim();
    return text.isNotEmpty && text != 'No content available';
  }

  // --- Helper Functions (Robust versions) ---

  static MessagePart? _findPartByMimeType(MessagePart? part, String mimeType) {
    if (part == null) return null;
    if (part.mimeType == mimeType) {
      return part;
    }
    if (part.parts != null) {
      for (final subPart in part.parts!) {
        final result = _findPartByMimeType(subPart, mimeType);
        if (result != null) {
          return result;
        }
      }
    }
    return null;
  }

  static String _decodeBase64(String data) {
    try {
      String normalizedData = data.replaceAll('-', '+').replaceAll('_', '/');
      final mod = normalizedData.length % 4;
      if (mod != 0) {
        normalizedData += '=' * (4 - mod);
      }
      return utf8.decode(base64.decode(normalizedData), allowMalformed: true);
    } catch (e) {
      return 'Failed to decode content';
    }
  }

  static String _convertHtmlToPlainText(String html) {
    try {
      final text = html
          .replaceAll(RegExp(r'<style>.*?</style>', caseSensitive: false, multiLine: true), ' ')
          .replaceAll(RegExp(r'<script>.*?</script>', caseSensitive: false, multiLine: true), ' ')
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      return HtmlUnescape().convert(text);
    } catch (e) {
      return 'Content preview not available';
    }
  }

  static String _extractSenderName(String from) => from.split('<').first.replaceAll('"', '').trim();
  static String _extractSenderEmail(String from) {
    final match = RegExp(r'<(.*?)>').firstMatch(from);
    return match?.group(1) ?? from.trim();
  }
  static bool _checkForAttachments(MessagePart? part) {
    if (part == null) return false;
    if (part.filename != null && part.filename!.isNotEmpty) return true;
    return part.parts?.any(_checkForAttachments) ?? false;
  }

  Email copyWith({
    String? summary,
    String? category,
    bool? isRead,
    String? body,
    String? htmlBody,
  }) {
    return Email(
      id: id,
      subject: subject,
      sender: sender,
      senderEmail: senderEmail,
      date: date,
      snippet: snippet,
      body: body ?? this.body,
      htmlBody: htmlBody ?? this.htmlBody, // Add htmlBody
      category: category ?? this.category,
      summary: summary ?? this.summary,
      isRead: isRead ?? this.isRead,
      hasAttachment: hasAttachment,
      cc: cc,
      bcc: bcc,
    );
  }
}
