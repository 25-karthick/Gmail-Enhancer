import 'package:flutter/material.dart';

import 'email_model.dart';

class EmailCategory {
  final String name;
  final String icon;
  final int count;
  final Color color;

  EmailCategory({
    required this.name,
    required this.icon,
    required this.count,
    required this.color,
  });

  // Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'count': count,
      'color': color.value,
    };
  }

  // Create from JSON for deserialization
  factory EmailCategory.fromJson(Map<String, dynamic> json) {
    return EmailCategory(
      name: json['name'],
      icon: json['icon'],
      count: json['count'],
      color: Color(json['color']),
    );
  }

  // Copy with method for immutability
  EmailCategory copyWith({
    String? name,
    String? icon,
    int? count,
    Color? color,
  }) {
    return EmailCategory(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      count: count ?? this.count,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmailCategory && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() {
    return 'EmailCategory(name: $name, count: $count)';
  }
}

class CategoryManager {
  static final Map<String, List<String>> categoryKeywords = {
    'Jobs': [
      'job', 'career', 'hiring', 'position', 'offer', 'recruitment',
      'application', 'interview', 'resume', 'cv', 'employment',
      'opportunity', 'vacancy', 'opening', 'role'
    ],
    'Internships': [
      'internship', 'intern', 'training', 'fellowship', 'graduate program',
      'summer program', 'campus placement', 'trainee', 'apprenticeship'
    ],
    'OTP/Security': [
      'otp', 'verification', 'security', 'login', 'password', 'authenticate',
      'code', 'verify', 'confirmation', 'reset', 'authentication',
      'one-time password', '2fa', 'two-factor'
    ],
    'Promotions': [
      'sale', 'discount', 'offer', 'promo', 'deal', 'coupon', 'limited time',
      'exclusive', 'buy now', 'shop', 'save', 'special', 'limited offer',
      'flash sale', 'clearance'
    ],
    'Social': [
      'facebook', 'twitter', 'linkedin', 'instagram', 'friend', 'connection',
      'follow', 'like', 'share', 'social', 'media', 'network', 'invitation'
    ],
    'Updates': [
      'update', 'newsletter', 'alert', 'notification', 'news', 'announcement',
      'report', 'summary', 'digest', 'bulletin'
    ],
    'Finance': [
      'invoice', 'payment', 'bill', 'receipt', 'transaction', 'bank',
      'credit', 'debit', 'refund', 'subscription', 'renewal'
    ],
    'Travel': [
      'flight', 'hotel', 'booking', 'reservation', 'itinerary', 'trip',
      'vacation', 'travel', 'airline'
    ],
    'Google': ['google', 'gmail', 'youtube', 'android', 'workspace'],
    'Microsoft': ['microsoft', 'office', 'windows', 'azure', 'outlook'],
    'IBM': ['ibm', 'watson', 'cloud', 'cognitive'],
    'TCS': ['tata consultancy', 'tcs', 'tata'],
    'Amazon': ['amazon', 'aws', 'prime'],
  };

  static String categorizeEmail(Email email) {
    final content = '${email.subject} ${email.snippet} ${email.body ?? ""}'.toLowerCase();

    // Check for exact company domains in sender email
    final senderEmail = email.senderEmail.toLowerCase();
    if (senderEmail.contains('@google.com') || senderEmail.contains('@gmail.com')) {
      return 'Google';
    } else if (senderEmail.contains('@microsoft.com')) {
      return 'Microsoft';
    } else if (senderEmail.contains('@ibm.com')) {
      return 'IBM';
    } else if (senderEmail.contains('@tcs.com')) {
      return 'TCS';
    } else if (senderEmail.contains('@amazon.com')) {
      return 'Amazon';
    }

    // Check category keywords
    for (final entry in categoryKeywords.entries) {
      if (entry.value.any((keyword) => content.contains(keyword))) {
        return entry.key;
      }
    }

    return 'General';
  }

  static List<EmailCategory> getDefaultCategories() {
    return [
      EmailCategory(name: 'All', icon: '📥', count: 0, color: Colors.blue),
      EmailCategory(name: 'Jobs', icon: '💼', count: 0, color: Colors.green),
      EmailCategory(name: 'Internships', icon: '🎓', count: 0, color: Colors.orange),
      EmailCategory(name: 'OTP/Security', icon: '🔒', count: 0, color: Colors.red),
      EmailCategory(name: 'Promotions', icon: '🎁', count: 0, color: Colors.purple),
      EmailCategory(name: 'Social', icon: '👥', count: 0, color: Colors.blue.shade300),
      EmailCategory(name: 'Updates', icon: '📢', count: 0, color: Colors.teal),
      EmailCategory(name: 'Finance', icon: '💰', count: 0, color: Colors.green.shade700),
      EmailCategory(name: 'Travel', icon: '✈️', count: 0, color: Colors.pink),
      EmailCategory(name: 'Google', icon: '🔵', count: 0, color: Colors.blue.shade700),
      EmailCategory(name: 'Microsoft', icon: '🔴', count: 0, color: Colors.blue.shade500),
      EmailCategory(name: 'IBM', icon: '🔵', count: 0, color: Colors.blue.shade900),
      EmailCategory(name: 'TCS', icon: '🔷', count: 0, color: Colors.blue.shade800),
      EmailCategory(name: 'Amazon', icon: '🟠', count: 0, color: Colors.orange.shade700),
      EmailCategory(name: 'General', icon: '📧', count: 0, color: Colors.grey),
    ];
  }

  static List<String> getCategoryNames() {
    return getDefaultCategories().map((cat) => cat.name).toList();
  }

  static String getCategoryIcon(String categoryName) {
    final category = getDefaultCategories().firstWhere(
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

  static Color getCategoryColor(String categoryName) {
    final category = getDefaultCategories().firstWhere(
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
}