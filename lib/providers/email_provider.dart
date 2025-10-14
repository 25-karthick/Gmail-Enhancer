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
      _error = 'Failed to load emails: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _categorizeEmails() {
    _emails = _emails.map((email) {
      final category = CategoryManager.categorizeEmail(email);
      return email.copyWith(category: category);
    }).toList();
  }

  void _applyFilters() {
    List<Email> filtered = _emails;

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

  Future<void> summarizeEmail(String emailId, String emailContent) async {
    _summaryLoadingStates[emailId] = true;
    notifyListeners();

    try {
      final summary = await _geminiService.summarizeEmail(emailContent);

      final index = _emails.indexWhere((email) => email.id == emailId);
      if (index != -1) {
        _emails[index] = _emails[index].copyWith(summary: summary);
        _applyFilters();
      }
    } catch (e) {
      print('Error summarizing email $emailId: $e');
    } finally {
      _summaryLoadingStates[emailId] = false;
      notifyListeners();
    }
  }

  bool isSummaryLoading(String emailId) {
    return _summaryLoadingStates[emailId] ?? false;
  }

  Future<void> refreshEmails() async {
    await loadEmails();
  }
}