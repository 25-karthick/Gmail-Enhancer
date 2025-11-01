import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/email_model.dart';
import '../../../providers/email_provider.dart';
import '../../../services/gmail_service.dart';

class SummaryButton extends StatefulWidget {
  final Email email;

  const SummaryButton({super.key, required this.email});

  @override
  State<SummaryButton> createState() => _SummaryButtonState();
}

class _SummaryButtonState extends State<SummaryButton> {
  bool _isLoading = false;

  Future<void> _generateSummary() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final emailProvider = Provider.of<EmailProvider>(context, listen: false);
      final gmailService = GmailService();

      // Use full email content for summarization
      String emailContent;

      if (widget.email.fullBody != null && widget.email.fullBody!.isNotEmpty) {
        emailContent = widget.email.fullBody!;
      } else {
        // Fetch full email body if not available
        emailContent = await gmailService.getEmailBody(widget.email.id);
      }

      // Include subject and sender in the content for better context
      final fullContent = '''
Subject: ${widget.email.subject}
From: ${widget.email.sender} <${widget.email.senderEmail}>
Date: ${widget.email.date}
CC: ${widget.email.cc.join(', ')}
BCC: ${widget.email.bcc.join(', ')}

Content:
$emailContent
''';

      // Generate summary
      await emailProvider.summarizeEmail(widget.email.id, fullContent);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Summary generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate summary: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailProvider = Provider.of<EmailProvider>(context);
    final isSummaryLoading = emailProvider.isSummaryLoading(widget.email.id);

    return ElevatedButton.icon(
      onPressed: (widget.email.summary != null || _isLoading || isSummaryLoading)
          ? null
          : _generateSummary,
      icon: _isLoading || isSummaryLoading
          ? const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : const Icon(Icons.auto_awesome, size: 16),
      label: Text(
        widget.email.summary != null ? 'Summarized' : 'Summarize',
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: widget.email.summary != null
            ? Colors.green.shade50
            : Colors.blue.shade50,
        foregroundColor: widget.email.summary != null
            ? Colors.green
            : Colors.blue,
      ),
    );
  }
}