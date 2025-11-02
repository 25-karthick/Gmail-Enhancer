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
    // No need for a separate _isLoading state here, the provider handles it
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);

    // The button's only job is to call the provider.
    await emailProvider.summarizeEmail(widget.email.id);
  }

  @override
  Widget build(BuildContext context) {
    final emailProvider = Provider.of<EmailProvider>(context);
    final isSummaryLoading = emailProvider.isSummaryLoading(widget.email.id);

    return ElevatedButton.icon(
      onPressed: (widget.email.summary != null || emailProvider.isSummaryLoading(widget.email.id))
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