import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart'; // 1. Import the webview package
import 'dart:convert'; // Import for base64 encoding
import '../models/email_model.dart';
import '../widgets/email/summary_button.dart';
import '../providers/email_provider.dart' hide Email;
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

  // 2. Create a controller for the WebView
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _currentEmail = widget.email;

    // 3. Initialize the WebView controller
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted); // Enable JavaScript

    // Load full content if not already available
    if (_currentEmail.fullBody == null || _currentEmail.fullBody!.isEmpty) {
      _loadFullContent();
    } else {
      _loadHtmlContent(); // Load the HTML we already have
    }
  }

  // 4. Create a function to load the HTML into the WebView
  void _loadHtmlContent() {
    // We get the full, raw HTML body from our email model.
    // The email model must be configured to extract this.
    final htmlContent = _currentEmail.fullBody ?? '<body>No content available</body>';

    // To display local HTML, we encode it in base64 and use a data URI.
    // This is the standard and most reliable way.
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
        _loadHtmlContent(); // Once content is loaded, put it in the WebView
      }
    } catch (e) {
      print('Error loading full content: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load full email content'),
          backgroundColor: Colors.red,
        ),
      );
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
          SummaryButton(email: _currentEmail),
        ],
      ),
      body: _isLoadingFullContent
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with sender, subject, etc.
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
          // 5. The WebView to render the HTML body
          Expanded(
            child: WebViewWidget(controller: _webViewController),
          ),
        ],
      ),
    );
  }

  // --- Helper widgets for sender, date, etc. remain the same ---
  Widget _buildSenderSection() {
    // (Your existing code for this widget)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue,
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
    // (Your existing code for this function)
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${DateFormat('EEEE').format(date)} at ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('MMM dd, yyyy at HH:mm').format(date);
    }
  }
}