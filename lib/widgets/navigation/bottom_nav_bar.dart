import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/email_provider.dart';
import '../../../screens/reminders_screen.dart'; // ✅ Import your reminder screen

class BottomNavBar extends StatefulWidget {
  final Function(int)? onTabSelected;

  const BottomNavBar({
    super.key,
    this.onTabSelected,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (widget.onTabSelected != null) {
      widget.onTabSelected!(index);
    }

    // ✅ When Reminder tab is tapped, navigate to the RemindersScreen
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RemindersScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailProvider = Provider.of<EmailProvider>(context);
    final unreadCount = emailProvider.allEmails
        .where((email) => !email.isRead)
        .length;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      showUnselectedLabels: true,
      items: [
        // Inbox Tab
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.inbox),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Inbox',
        ),

        // Important Tab
        const BottomNavigationBarItem(
          icon: Icon(Icons.star_border),
          activeIcon: Icon(Icons.star),
          label: 'Important',
        ),

        // ✅ Reminder Tab (was Sent)
        const BottomNavigationBarItem(
          icon: Icon(Icons.alarm),
          activeIcon: Icon(Icons.alarm_on),
          label: 'Reminder',
        ),

        // Categories Tab
        const BottomNavigationBarItem(
          icon: Icon(Icons.category_outlined),
          activeIcon: Icon(Icons.category),
          label: 'Categories',
        ),

        // Settings Tab
        const BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
