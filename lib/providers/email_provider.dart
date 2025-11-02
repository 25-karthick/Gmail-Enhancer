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
    _emails = _emails.map((email) {
      // Use the manager you built to get the category name
      final categoryName = CategoryManager.categorizeEmail(email);
      // Use the copyWith method to create an updated email object
      return email.copyWith(category: categoryName);
    }).toList();
  }

  // **THE CORRECTED METHOD IS BELOW**
  Future<void> summarizeEmail(String emailId) async {
    _summaryLoadingStates[emailId] = true;
    notifyListeners();

    try {
      final index = _emails.indexWhere((e) => e.id == emailId);
      if (index == -1) throw Exception('Email not found.');

      var email = _emails[index];

      // Fetch full content ONLY if it's missing. This is efficient.
      if (email.fullBody == null || email.fullBody!.isEmpty) {
        final completeEmail = await _gmailService.getCompleteEmail(emailId);
        if (completeEmail != null) {
          email = completeEmail; // Update our local copy with the full body
        }
      }

      if (!email.hasValidContent) {
        throw Exception('Email has no content to summarize.');
      }

      final summary = await _geminiService.summarizeEmail(
        subject: email.subject,
        emailContent: email.displayBody, // Use the smart getter from your model
      );

      // Update the master list and apply filters
      _emails[index] = email.copyWith(summary: summary);
      _applyFilters();

    } catch (e) {
      print('Error summarizing email $emailId: $e');
      final index = _emails.indexWhere((e) => e.id == emailId);
      if (index != -1) {
        _emails[index] = _emails[index].copyWith(summary: 'Summary failed to load.');
        _applyFilters(); // Ensure UI updates with the error message
      }
    } finally {
      _summaryLoadingStates[emailId] = false;
      notifyListeners();
    }
  }


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