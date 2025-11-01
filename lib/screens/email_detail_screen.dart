import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/email_model.dart';
import '../widgets/email/summary_button.dart';
import '../providers/email_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _currentEmail = widget.email;
    // Load full content if not already available
    if (_currentEmail.fullBody == null || _currentEmail.fullBody!.isEmpty) {
      _loadFullContent();
    }
  }

  Future<void> _loadFullContent() async {
    if (_isLoadingFullContent) return;

    setState(() {
      _isLoadingFullContent = true;
    });

    try {
      final gmailService = GmailService();
      final completeEmail = await gmailService.getCompleteEmail(_currentEmail.id);

      if (completeEmail != null && mounted) {
        setState(() {
          _currentEmail = completeEmail;
        });
      }
    } catch (e) {
      print('Error loading full content: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load full email content'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFullContent = false;
        });
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
          : _buildEmailContent(),
    );
  }

  Widget _buildEmailContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject
          Text(
            _currentEmail.subject,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Sender Information
          _buildSenderSection(),
          const SizedBox(height: 16),

          // Date
          Text(
            'Date: ${_formatDate(_currentEmail.date)}',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // CC Recipients
          if (_currentEmail.cc.isNotEmpty) ...[
            _buildRecipientSection('CC:', _currentEmail.cc),
            const SizedBox(height: 12),
          ],

          // BCC Recipients
          if (_currentEmail.bcc.isNotEmpty) ...[
            _buildRecipientSection('BCC:', _currentEmail.bcc),
            const SizedBox(height: 12),
          ],

          // Category
          _buildCategoryChip(),
          const SizedBox(height: 20),

          // AI Summary Section
          if (_currentEmail.summary != null && _currentEmail.summary!.isNotEmpty) ...[
            _buildSummarySection(),
            const SizedBox(height: 20),
          ],

          // Email Body
          _buildEmailBodySection(),
        ],
      ),
    );
  }

  Widget _buildSenderSection() {
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

  Widget _buildRecipientSection(String title, List<String> recipients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: recipients.map((email) => Chip(
            label: Text(
              email,
              style: const TextStyle(fontSize: 12),
            ),
            visualDensity: VisualDensity.compact,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip() {
    return Chip(
      label: Text(
        _currentEmail.category,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: _getCategoryColor(_currentEmail.category),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'AI Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentEmail.summary!,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailBodySection() {
    final bodyContent = _currentEmail.fullBody ?? _currentEmail.body ?? _currentEmail.snippet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Content:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SelectableText(
            bodyContent,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Jobs': Colors.green,
      'Internships': Colors.orange,
      'OTP/Security': Colors.red,
      'Promotions': Colors.purple,
      'Social': Colors.blue,
      'Updates': Colors.teal,
      'Google': Colors.blue.shade700,
      'Microsoft': Colors.blue.shade500,
      'IBM': Colors.blue.shade900,
      'TCS': Colors.blue.shade800,
      'General': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  String _formatDate(DateTime date) {
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