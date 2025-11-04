import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import '../models/email_model.dart';
import '../widgets/email/summary_button.dart';
import '../services/gmail_service.dart';

class EmailDetailScreen extends StatefulWidget {
  final Email email;

  const EmailDetailScreen({super.key, required this.email});

  @override
  State<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends State<EmailDetailScreen> {
  late Email _currentEmail;
  bool _isLoadingFullContent = false;
  late final WebViewController _webViewController;

  /// Helper getter to implement your idea of hiding the button
  bool get isSummarizable {
    return _currentEmail.hasValidContent &&
        _currentEmail.plainTextBodyForAI.trim().length >= 50 &&
        _currentEmail.summary == null;
  }

  @override
  void initState() {
    super.initState();
    _currentEmail = widget.email;

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    // 1. Check for the new properties
    if (_currentEmail.body == null && _currentEmail.htmlBody == null) {
      _loadFullContent();
    } else {
      _loadHtmlContent();
    }
  }

  void _loadHtmlContent() {
    // 2. ✅ THE FIX: Use the correct getter for the WebView
    final htmlContent = _currentEmail.displayBodyForWebView;

    _webViewController.loadRequest(
      Uri.dataFromString(
        htmlContent,
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8'),
      ),
    );
  }

  Future<void> _loadFullContent() async {
    if (_isLoadingFullContent) return;
    setState(() => _isLoadingFullContent = true);

    try {
      final gmailService = GmailService();
      final completeEmail = await gmailService.getCompleteEmail(_currentEmail.id);

      if (completeEmail != null && mounted) {
        setState(() {
          _currentEmail = completeEmail;
        });
        _loadHtmlContent(); // Now load the full content
      }
    } catch (e) {
      print('Error loading full content: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingFullContent = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Details'),
        actions: [
          // 3. ✅ THE FIX: Only show the button if it's summarizable
          if (isSummarizable)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SummaryButton(email: _currentEmail),
            ),
        ],
      ),
      body: _isLoadingFullContent
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentEmail.subject,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSenderSection(),
                const SizedBox(height: 16),
                Text(
                  'Date: ${_formatDate(_currentEmail.date)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // WebView to render the HTML body
          Expanded(
            child: WebViewWidget(controller: _webViewController),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue, // You can use CategoryManager here
          child: Text(
            _currentEmail.sender.isNotEmpty
                ? _currentEmail.sender[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentEmail.sender,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentEmail.senderEmail,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}
