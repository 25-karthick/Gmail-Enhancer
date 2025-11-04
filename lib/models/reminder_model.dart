// lib/models/reminder_model.dart
import 'package:flutter/foundation.dart';

class ReminderModel {
  final int id;
  final String title;
  final DateTime scheduledTime;

  ReminderModel({
    required this.id,
    required this.title,
    required this.scheduledTime,
  });

  ReminderModel copyWith({
    int? id,
    String? title,
    DateTime? scheduledTime,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      scheduledTime: scheduledTime ?? this.scheduledTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      // store time as ISO8601 string to be portable and timezone-safe
      'scheduledTime': scheduledTime.toIso8601String(),
    };
  }

  /// fromJson expects the same structure produced by toJson()
  /// Accepts either int or string for `id`.
  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw ArgumentError('json must not be null');
    }

    // id: accept int or numeric string
    final dynamic rawId = json['id'];
    int id;
    if (rawId is int) {
      id = rawId;
    } else if (rawId is String) {
      id = int.tryParse(rawId) ?? rawId.hashCode;
    } else {
      id = json.hashCode;
    }

    final rawTitle = json['title'] ?? '';
    final String title = rawTitle.toString();

    final rawTime = json['scheduledTime'];
    DateTime scheduledTime;
    if (rawTime is String) {
      scheduledTime = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else if (rawTime is int) {
      // epoch millis
      scheduledTime = DateTime.fromMillisecondsSinceEpoch(rawTime);
    } else {
      scheduledTime = DateTime.now();
    }

    return ReminderModel(
      id: id,
      title: title,
      scheduledTime: scheduledTime,
    );
  }

  @override
  String toString() => 'ReminderModel(id: $id, title: $title, scheduledTime: $scheduledTime)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ReminderModel &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              title == other.title &&
              scheduledTime == other.scheduledTime;

  @override
  int get hashCode => id ^ title.hashCode ^ scheduledTime.hashCode;
}
