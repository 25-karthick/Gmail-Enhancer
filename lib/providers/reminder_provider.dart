// lib/providers/reminder_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_model.dart';
import '../services/notification_services.dart';
import 'package:intl/intl.dart';

class ReminderProvider extends ChangeNotifier {
  List<ReminderModel> _reminders = [];
  List<ReminderModel> get reminders => List.unmodifiable(_reminders);

  static const _storageKey = 'saved_reminders';

  ReminderProvider() {
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_storageKey) ?? [];

      final List<ReminderModel> loaded = [];
      for (final jsonStr in saved) {
        try {
          final Map<String, dynamic> map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final reminder = ReminderModel.fromJson(map);
          loaded.add(reminder);
        } catch (e, st) {
          // Skip invalid entry but log for debugging
          debugPrint('ReminderProvider: failed parsing saved reminder: $e\n$st\nSkipping entry.');
        }
      }

      _reminders = loaded;

      // Re-schedule notifications for upcoming reminders
      for (var reminder in _reminders) {
        if (reminder.scheduledTime.isAfter(DateTime.now())) {
          await NotificationService.scheduleNotification(
            id: reminder.id,
            title: "Reminder: ${reminder.title}",
            body:
            "Scheduled for ${DateFormat('hh:mm a, dd MMM yyyy').format(reminder.scheduledTime)}",
            scheduledTime: reminder.scheduledTime,
          );
          debugPrint('Rescheduled reminder id=${reminder.id} at ${reminder.scheduledTime}');
        } else {
          // Optional: if you want to show missed reminders immediately on app start:
          // await NotificationService.show(...);
        }
      }

      notifyListeners();
    } catch (e, st) {
      debugPrint('ReminderProvider: _loadReminders failed: $e\n$st');
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _reminders.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_storageKey, data);
  }

  Future<void> addReminder(ReminderModel reminder) async {
    _reminders.add(reminder);
    await _saveReminders();

    // Schedule immediately when added
    await NotificationService.scheduleNotification(
      id: reminder.id,
      title: "Reminder: ${reminder.title}",
      body:
      "Scheduled for ${DateFormat('hh:mm a, dd MMM yyyy').format(reminder.scheduledTime)}",
      scheduledTime: reminder.scheduledTime,
    );

    notifyListeners();
  }

  Future<void> removeReminder(int index) async {
    final reminder = _reminders[index];
    _reminders.removeAt(index);
    await NotificationService.cancelNotification(reminder.id);
    await _saveReminders();
    notifyListeners();
  }

  Future<void> clearAll() async {
    // cancel all scheduled notifications for reminders
    for (var r in _reminders) {
      await NotificationService.cancelNotification(r.id);
    }
    _reminders.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }
}
