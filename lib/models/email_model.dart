import 'package:googleapis/gmail/v1.dart';
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
  });

  factory Email.fromGmailApi(Message message) {
    // Use the typed MessagePart object, not a Map
    final MessagePart? payload = message.payload;
    final List<MessagePartHeader> headers = payload?.headers ?? [];

    // Helper function to safely find header values
    String findHeaderValue(String name) {
      final header = headers.firstWhere(
            (h) => h.name?.toLowerCase() == name.toLowerCase(),
        orElse: () => MessagePartHeader(), // Return an empty header if not found
      );
      return header.value ?? '';
    }

    final String fromHeader = findHeaderValue('From');
    final String subject = findHeaderValue('Subject').isEmpty ? '(No Subject)' : findHeaderValue('Subject');

    return Email(
      id: message.id!,
      subject: subject,
      sender: _extractSenderName(fromHeader),
      senderEmail: _extractSenderEmail(fromHeader),
      // The internalDate is a string of milliseconds since epoch
      date: DateTime.fromMillisecondsSinceEpoch(
          int.parse(message.internalDate!),
          isUtc: true // Gmail dates are UTC
      ).toLocal(), // Convert to local time for display
      snippet: message.snippet ?? '',
      isRead: !(message.labelIds?.contains('UNREAD') ?? false),
    );
  }

  static String _extractSenderName(String from) {
    final regex = RegExp(r'(.+?)<(.+?)>');
    final match = regex.firstMatch(from);
    return match != null ? match.group(1)!.trim() : from;
  }

  static String _extractSenderEmail(String from) {
    final regex = RegExp(r'<(.+?)>');
    final match = regex.firstMatch(from);
    return match != null ? match.group(1)! : from;
  }

  Email copyWith({
    String? summary,
    String? category,
    bool? isRead,
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
      hasAttachment: hasAttachment,
    );
  }
}