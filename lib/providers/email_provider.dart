import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/email_model.dart';
import '../services/gmail_service.dart';
import '../services/gemini_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailProvider with ChangeNotifier {
  final GmailService _gmailService = GmailService();
  final GeminiService _geminiService = GeminiService();

  List<Email> _emails = [];
  List<Email> _filteredEmails = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  final Map<String, bool> _summaryLoadingStates = {};

  List<Email> get emails => _filteredEmails;
  List<Email> get allEmails => _emails;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;

  EmailProvider() {
    loadEmails();
  }

  Future<void> loadEmails() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _emails = await _gmailService.fetchEmails();
      _categorizeEmails();
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshEmails() async {
    _emails = [];
    _filteredEmails = [];
    _summaryLoadingStates.clear();
    await loadEmails();
  }

  void _categorizeEmails() {
    // This method is missing in the snippets, but assumed to exist
    // It would update email.category based on some logic (e.g., sender/subject)
    // Placeholder implementation:
    // This is where you would call your categorization logic if you had one.
    // For now, it just ensures all emails are marked as 'General' if category is null.
    _emails = _emails.map((email) {
      return email.category.isEmpty ? email.copyWith(category: 'General') : email;
    }).toList();
  }

  // **THE CORRECTED METHOD IS BELOW**
  Future<void> summarizeEmail(String emailId, String emailContent) async {
    _summaryLoadingStates[emailId] = true;
    notifyListeners();

    try {
      // 1. Find the email in your list to get its subject and body
      final index = _emails.indexWhere((email) => email.id == emailId);
      if (index == -1) {
        throw Exception('Email $emailId not found.');
      }
      final email = _emails[index];

      // Use the body from the Email Model (which likely handles full vs snippet)
      final contentToSummarize = email.displayBody; // Assuming you have a getter for this

      if (contentToSummarize.isEmpty || contentToSummarize == 'No content available') {
        throw Exception('No valid content to summarize.');
      }

      // 2. Call the service with the REAL data
      final summary = await _geminiService.summarizeEmail(
        subject: email.subject,
        emailContent: contentToSummarize,
      );

      // 3. Update the email in the list
      _emails[index] = _emails[index].copyWith(summary: summary);
      _applyFilters(); // This will update _filteredEmails and notify listeners

    } catch (e) {
      print('Error summarizing email $emailId: $e');

      // Set a failed summary message so the user knows it failed
      final index = _emails.indexWhere((email) => email.id == emailId);
      if (index != -1) {
        _emails[index] = _emails[index].copyWith(summary: 'Summary failed to load.');
        _applyFilters();
      }

    } finally {
      _summaryLoadingStates[emailId] = false;
      notifyListeners(); // Notify again to stop the loading indicator
    }
  }
  // **END OF CORRECTED METHOD**


  bool isSummaryLoading(String emailId) => _summaryLoadingStates[emailId] == true;

  void _applyFilters() {
    var filtered = _emails.toList();

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((email) => email.category == _selectedCategory).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((email) =>
      email.subject.toLowerCase().contains(query) ||
          email.sender.toLowerCase().contains(query) ||
          email.snippet.toLowerCase().contains(query) ||
          (email.summary?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    _filteredEmails = filtered;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }
}