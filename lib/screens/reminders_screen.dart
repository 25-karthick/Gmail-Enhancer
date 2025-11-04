// lib/screens/reminders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/reminder_provider.dart';
import '../models/reminder_model.dart';
import '../services/notification_services.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDateTime;

  /// 🕒 Pick date and time for the reminder
  Future<void> _pickDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  /// ✅ Add a new reminder, save it, and schedule notification
  Future<void> _addReminder(BuildContext context) async {
    final reminderProvider =
    Provider.of<ReminderProvider>(context, listen: false);

    if (_titleController.text.isEmpty || _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title and select date & time'),
        ),
      );
      return;
    }

    // Create unique int ID for this reminder
    final int id = DateTime.now().millisecondsSinceEpoch.remainder(1000000);

    // ✅ Create new ReminderModel (id is int)
    final newReminder = ReminderModel(
      id: id,
      title: _titleController.text.trim(),
      scheduledTime: _selectedDateTime!,
    );

    // Add to provider (which will persist it and schedule notification again)
    await reminderProvider.addReminder(newReminder);

    // Schedule notification explicitly (works even if time is in the past)
    await NotificationService.scheduleNotification(
      id: id,
      title: "Reminder: ${newReminder.title}",
      body:
      "Scheduled for ${DateFormat('hh:mm a, dd MMM yyyy').format(newReminder.scheduledTime)}",
      scheduledTime: newReminder.scheduledTime,
    );

    // Reset inputs
    _titleController.clear();
    setState(() => _selectedDateTime = null);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Reminder added successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminderProvider = Provider.of<ReminderProvider>(context);
    final reminders = reminderProvider.reminders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧾 Title input
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Reminder Title",
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 🕒 Date & Time picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedDateTime == null
                        ? "No time selected"
                        : "📅 ${DateFormat('hh:mm a, dd MMM yyyy').format(_selectedDateTime!)}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickDateTime(context),
                  icon: const Icon(Icons.access_time),
                  label: const Text("Pick Time"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ➕ Add reminder button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _addReminder(context),
                icon: const Icon(Icons.add_alert),
                label: const Text("Add Reminder"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(thickness: 1),

            // 📋 List of reminders
            const Text(
              "Your Reminders:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: reminders.isEmpty
                  ? const Center(
                child: Text(
                  "No reminders added yet.",
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading:
                      const Icon(Icons.alarm, color: Colors.blue),
                      title: Text(reminder.title),
                      subtitle: Text(
                        DateFormat('hh:mm a, dd MMM yyyy')
                            .format(reminder.scheduledTime),
                      ),
                      trailing: IconButton(
                        icon:
                        const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          reminderProvider.removeReminder(index);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('🗑️ Reminder deleted')),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
