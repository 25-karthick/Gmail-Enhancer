import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/email_model.dart';

class CategoryProvider with ChangeNotifier {
  List<EmailCategory> _categories = [];
  String _selectedCategory = 'All';
  Map<String, int> _categoryCounts = {};
  bool _isLoading = false;

  List<EmailCategory> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  Map<String, int> get categoryCounts => _categoryCounts;
  bool get isLoading => _isLoading;

  CategoryProvider() {
    _initializeCategories();
  }

  void _initializeCategories() {
    _categories = CategoryManager.getDefaultCategories();
    _updateCategoryCounts([]); // Initialize with empty counts
  }

  void updateCategoryCounts(List<Email> emails) {
    _updateCategoryCounts(emails);
    notifyListeners();
  }

  void _updateCategoryCounts(List<Email> emails) {
    _categoryCounts.clear();

    // Count emails for each category
    for (final category in _categories) {
      final count = emails.where((email) => email.category == category.name).length;
      _categoryCounts[category.name] = count;
    }

    // Update category objects with counts
    _categories = _categories.map((category) {
      return EmailCategory(
        name: category.name,
        icon: category.icon,
        count: _categoryCounts[category.name] ?? 0,
        color: category.color,
      );
    }).toList();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void selectCategory(String category) {
    if (_categories.any((cat) => cat.name == category)) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  void resetToAll() {
    _selectedCategory = 'All';
    notifyListeners();
  }

  List<Email> filterEmailsByCategory(List<Email> emails, String category) {
    if (category == 'All') {
      return emails;
    }
    return emails.where((email) => email.category == category).toList();
  }

  List<Email> filterEmailsByCurrentCategory(List<Email> emails) {
    return filterEmailsByCategory(emails, _selectedCategory);
  }

  Map<String, List<Email>> groupEmailsByCategory(List<Email> emails) {
    final grouped = <String, List<Email>>{};

    for (final email in emails) {
      if (!grouped.containsKey(email.category)) {
        grouped[email.category] = [];
      }
      grouped[email.category]!.add(email);
    }

    return grouped;
  }

  List<EmailCategory> getCategoriesWithEmails(List<Email> emails) {
    updateCategoryCounts(emails);
    return _categories.where((category) => category.count > 0).toList();
  }

  List<EmailCategory> getTopCategories(List<Email> emails, {int limit = 5}) {
    updateCategoryCounts(emails);

    final sortedCategories = List<EmailCategory>.from(_categories)
      ..sort((a, b) => b.count.compareTo(a.count));

    return sortedCategories.take(limit).toList();
  }

  String getCategoryIcon(String categoryName) {
    final category = _categories.firstWhere(
          (cat) => cat.name == categoryName,
      orElse: () => EmailCategory(
        name: categoryName,
        icon: '📧',
        count: 0,
        color: Colors.grey,
      ),
    );
    return category.icon;
  }

  Color getCategoryColor(String categoryName) {
    final category = _categories.firstWhere(
          (cat) => cat.name == categoryName,
      orElse: () => EmailCategory(
        name: categoryName,
        icon: '📧',
        count: 0,
        color: Colors.grey,
      ),
    );
    return category.color;
  }

  void addCustomCategory(String name, String icon, Color color) {
    if (!_categories.any((cat) => cat.name == name)) {
      _categories.add(EmailCategory(
        name: name,
        icon: icon,
        count: 0,
        color: color,
      ));
      notifyListeners();
    }
  }

  void removeCategory(String name) {
    if (name != 'All' && name != 'General') {
      _categories.removeWhere((cat) => cat.name == name);
      if (_selectedCategory == name) {
        _selectedCategory = 'All';
      }
      notifyListeners();
    }
  }

  void updateCategory(String oldName, String newName, String newIcon, Color newColor) {
    final index = _categories.indexWhere((cat) => cat.name == oldName);
    if (index != -1) {
      _categories[index] = EmailCategory(
        name: newName,
        icon: newIcon,
        count: _categories[index].count,
        color: newColor,
      );
      if (_selectedCategory == oldName) {
        _selectedCategory = newName;
      }
      notifyListeners();
    }
  }

  // Smart categorization suggestions
  List<String> getSuggestedCategories(List<Email> emails, {int limit = 3}) {
    final companyCounts = <String, int>{};

    for (final email in emails) {
      final senderDomain = _extractDomain(email.senderEmail);
      if (senderDomain.isNotEmpty) {
        companyCounts[senderDomain] = (companyCounts[senderDomain] ?? 0) + 1;
      }
    }

    final sortedDomains = companyCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedDomains.take(limit).map((entry) => entry.key).toList();
  }

  String _extractDomain(String email) {
    try {
      final atIndex = email.indexOf('@');
      if (atIndex != -1) {
        return email.substring(atIndex + 1).split('.')[0];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting domain: $e');
      }
    }
    return '';
  }

  // Analytics methods
  Map<String, dynamic> getCategoryAnalytics(List<Email> emails) {
    updateCategoryCounts(emails);

    final totalEmails = emails.length;
    final categoryPercentages = <String, double>{};

    for (final category in _categories) {
      if (totalEmails > 0) {
        categoryPercentages[category.name] = (category.count / totalEmails) * 100;
      }
    }

    return {
      'totalEmails': totalEmails,
      'categoryCounts': _categoryCounts,
      'categoryPercentages': categoryPercentages,
      'mostCommonCategory': _getMostCommonCategory(),
      'leastCommonCategory': _getLeastCommonCategory(),
    };
  }

  String _getMostCommonCategory() {
    if (_categoryCounts.isEmpty) return 'None';

    final sorted = _categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  String _getLeastCommonCategory() {
    if (_categoryCounts.isEmpty) return 'None';

    final sorted = _categoryCounts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return sorted.first.key;
  }

  // Search within categories
  List<Email> searchInCategory(List<Email> emails, String query) {
    final filteredByCategory = filterEmailsByCurrentCategory(emails);

    if (query.isEmpty) {
      return filteredByCategory;
    }

    final lowercaseQuery = query.toLowerCase();
    return filteredByCategory.where((email) =>
    email.subject.toLowerCase().contains(lowercaseQuery) ||
        email.sender.toLowerCase().contains(lowercaseQuery) ||
        email.snippet.toLowerCase().contains(lowercaseQuery) ||
        (email.summary?.toLowerCase().contains(lowercaseQuery) ?? false) ||
        email.senderEmail.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  // Bulk operations
  void bulkCategorizeEmails(List<Email> emails, String category) {
    // This would typically update the emails in the backend
    // For now, we just update the local state
    notifyListeners();
  }

  void clearSelection() {
    _selectedCategory = 'All';
    notifyListeners();
  }

  bool isCategorySelected(String category) {
    return _selectedCategory == category;
  }

  int getSelectedCategoryCount(List<Email> emails) {
    if (_selectedCategory == 'All') {
      return emails.length;
    }
    return emails.where((email) => email.category == _selectedCategory).length;
  }

  // Export category data
  Map<String, dynamic> exportCategoryData() {
    return {
      'selectedCategory': _selectedCategory,
      'categories': _categories.map((cat) => cat.toJson()).toList(),
      'categoryCounts': _categoryCounts,
    };
  }

  // Import category data
  void importCategoryData(Map<String, dynamic> data) {
    if (data['categories'] != null) {
      _categories = (data['categories'] as List)
          .map((json) => EmailCategory.fromJson(json))
          .toList();
    }

    if (data['selectedCategory'] != null) {
      _selectedCategory = data['selectedCategory'];
    }

    if (data['categoryCounts'] != null) {
      _categoryCounts = Map<String, int>.from(data['categoryCounts']);
    }

    notifyListeners();
  }
}