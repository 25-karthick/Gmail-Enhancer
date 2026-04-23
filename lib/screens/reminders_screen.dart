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

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDateTime;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  /// 🕒 Pick date and time for the reminder
  Future<void> _pickDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.indigo.shade900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.indigo.shade900,
            ),
          ),
          child: child!,
        );
      },
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
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent.shade200,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Please enter a title and select date & time', style: TextStyle(color: Colors.white)),
            ],
          ),
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
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.teal.shade500,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Reminder added successfully', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminderProvider = Provider.of<ReminderProvider>(context);
    final reminders = reminderProvider.reminders;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB), // Light nice background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.indigo.shade900,
        centerTitle: true,
        title: const Text(
          'Reminders',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📋 CREATE REMINDER CARD
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.shade100.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.notifications_active_rounded, 
                                color: Colors.indigo.shade600, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "New Reminder",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // 🧾 Title input
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: "What do you need to remember?",
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: Icon(Icons.edit_note_rounded, color: Colors.indigo.shade300),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.indigo.shade300, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 🕒 Date & Time picker
                      InkWell(
                        onTap: () => _pickDateTime(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_rounded, 
                                  color: _selectedDateTime != null ? Colors.indigo : Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDateTime == null
                                      ? "Pick date & time"
                                      : DateFormat('MMM dd, yyyy  •  hh:mm a').format(_selectedDateTime!),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: _selectedDateTime == null ? FontWeight.normal : FontWeight.w600,
                                    color: _selectedDateTime == null ? Colors.grey.shade600 : Colors.indigo.shade900,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // ➕ Add reminder button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => _addReminder(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade600,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: Colors.indigo.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_task_rounded),
                              SizedBox(width: 8),
                              Text(
                                "Create Reminder",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              // 📋 LIST ITEMS HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    const Text(
                      "Upcoming",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${reminders.length}",
                        style: TextStyle(
                          color: Colors.indigo.shade700,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 📋 BUILDER LIST
              Expanded(
                child: reminders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_rounded, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              "You're all caught up!",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        physics: const BouncingScrollPhysics(),
                        itemCount: reminders.length,
                        itemBuilder: (context, index) {
                          final reminder = reminders[index];
                          final isPast = reminder.scheduledTime.isBefore(DateTime.now());
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Dismissible(
                                key: Key(reminder.id.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: Colors.red.shade400,
                                  child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 30),
                                ),
                                onDismissed: (direction) {
                                  reminderProvider.removeReminder(index);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      content: const Text('Reminder deleted'),
                                      action: SnackBarAction(
                                        label: "OK",
                                        onPressed: () {},
                                        textColor: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      // ICON CLOCK
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: isPast ? Colors.grey.shade100 : Colors.indigo.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isPast ? Icons.history_rounded : Icons.alarm_rounded,
                                          color: isPast ? Colors.grey.shade400 : Colors.indigo.shade500,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // TEXT DETAIL
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              reminder.title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: isPast ? Colors.grey.shade500 : Colors.black87,
                                                decoration: isPast ? TextDecoration.lineThrough : null,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              DateFormat('MMM dd, yyyy • hh:mm a').format(reminder.scheduledTime),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: isPast ? Colors.grey.shade400 : Colors.indigo.shade400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // DELETE BUTTON (If not swiped)
                                      IconButton(
                                        icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade400),
                                        onPressed: () {
                                          reminderProvider.removeReminder(index);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              content: const Text('Reminder deleted'),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
