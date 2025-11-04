import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/email_model.dart';
import '../../../providers/category_provider.dart'; // Import CategoryProvider
import '../../../providers/email_provider.dart';
import '../../screens/email_detail_screen.dart';
import 'summary_button.dart';

class EmailCard extends StatelessWidget {
  final Email email;

  const EmailCard({super.key, required this.email});

  /// ✅ This getter uses the new model properties to
  /// implement your idea of hiding the button.
  bool get isSummarizable {
    return email.hasValidContent &&
        email.plainTextBodyForAI.trim().length >= 50 &&
        email.summary == null;
  }

  @override
  Widget build(BuildContext context) {
    // We use `read` here for the color logic, which doesn't need to rebuild
    final categoryProvider = context.read<CategoryProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          // Mark as read when tapped
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmailDetailScreen(email: email),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSenderInfo(categoryProvider),
              const SizedBox(height: 12),
              Text(
                email.subject.isNotEmpty ? email.subject : '(No Subject)',
                style: TextStyle(
                  fontWeight: email.isRead ? FontWeight.w500 : FontWeight.w700,
                  fontSize: 14,
                  color: email.isRead ? Colors.grey.shade700 : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (email.snippet.isNotEmpty) ...[
                Text(
                  email.snippet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: email.isRead ? FontWeight.w400 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (email.summary != null && email.summary!.isNotEmpty) ...[
                _buildSummarySection(),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      _formatDate(email.date),
                      style: TextStyle(
                        color: email.isRead ? Colors.grey.shade500 : Colors.blue,
                        fontSize: 11,
                        fontWeight: email.isRead ? FontWeight.w400 : FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // ✅ THE FIX: The button is now wrapped in this condition
                  if (isSummarizable)
                    SummaryButton(email: email),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSenderInfo(CategoryProvider categoryProvider) {
    final categoryColor = categoryProvider.getCategoryColor(email.category);
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: categoryColor,
          radius: 20,
          child: Text(
            email.sender.isNotEmpty ? email.sender[0].toUpperCase() : '?',
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
                email.sender.isNotEmpty ? email.sender : 'Unknown Sender',
                style: TextStyle(
                  fontWeight: email.isRead ? FontWeight.w600 : FontWeight.w800,
                  fontSize: 16,
                  color: email.isRead ? Colors.grey.shade800 : Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                email.senderEmail.isNotEmpty ? email.senderEmail : 'No email',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Chip(
          label: Text(
            email.category,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: categoryColor.withOpacity(0.2),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.shade100,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Summary',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email.summary!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return 'Today, ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}
