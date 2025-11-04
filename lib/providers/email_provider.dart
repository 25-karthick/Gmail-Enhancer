import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/email_model.dart';
import '../services/gmail_service.dart';
import '../services/gemini_service.dart';

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
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshEmails() async {
    await loadEmails();
  }

  void _categorizeEmails() {
    _emails = _emails.map((email) {
      final categoryName = CategoryManager.categorizeEmail(email);
      return email.copyWith(category: categoryName);
    }).toList();
  }

  Future<void> summarizeEmail(String emailId) async {
    _summaryLoadingStates[emailId] = true;
    notifyListeners();

    try {
      final index = _emails.indexWhere((e) => e.id == emailId);
      if (index == -1) throw Exception('Email not found.');

      var email = _emails[index];

      // 1. ✅ THE FIX: Check for the new properties
      if (email.body == null && email.htmlBody == null) {
        final completeEmail = await _gmailService.getCompleteEmail(emailId);
        if (completeEmail != null) {
          email = completeEmail;
        }
      }

      // 2. ✅ THE FIX: Use the new getters for the pre-flight check
      if (!email.hasValidContent || email.plainTextBodyForAI.trim().length < 50) {
        _emails[index] = email.copyWith(summary: 'Not enough content to summarize.');
        _applyFilters();
        return;
      }

      // 3. ✅ THE FIX: Send the correct plain text body to Gemini
      final summary = await _geminiService.summarizeEmail(
        subject: email.subject,
        emailContent: email.plainTextBodyForAI,
      );

      _emails[index] = email.copyWith(summary: summary);
      _applyFilters();

    } catch (e) {
      print('Error summarizing email $emailId: $e');
      final index = _emails.indexWhere((e) => e.id == emailId);
      if (index != -1) {
        _emails[index] = _emails[index].copyWith(summary: 'Summary failed to load.');
        _applyFilters();
      }
    } finally {
      _summaryLoadingStates[emailId] = false;
      notifyListeners();
    }
  }

  bool isSummaryLoading(String emailId) => _summaryLoadingStates[emailId] ?? false;

  void _applyFilters() {
    var filtered = _emails.toList();

    if (_selectedCategory != 'All') {
      filtered = filtered.where((email) => email.category == _selectedCategory).toList();
    }
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
