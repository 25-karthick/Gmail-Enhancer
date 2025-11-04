import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/email_model.dart';
import '../../../providers/email_provider.dart';
// No longer need to import GmailService

class SummaryButton extends StatefulWidget {
  final Email email;

  const SummaryButton({super.key, required this.email});

  @override
  State<SummaryButton> createState() => _SummaryButtonState();
}

class _SummaryButtonState extends State<SummaryButton> {
  // 1. Remove the local _isLoading state.

  Future<void> _generateSummary() async {
    // 2. The button's only job is to call the provider.
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);
    await emailProvider.summarizeEmail(widget.email.id);
  }

  @override
  Widget build(BuildContext context) {
    // 3. Use context.watch to get the *live* loading state from the provider
    final emailProvider = context.watch<EmailProvider>();
    final isSummaryLoading = emailProvider.isSummaryLoading(widget.email.id);

    return ElevatedButton.icon(
      // 4. The onPressed check is now much cleaner
      onPressed: (widget.email.summary != null || isSummaryLoading)
          ? null // Button is disabled if summary exists OR it's loading
          : _generateSummary,
      icon: isSummaryLoading
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
