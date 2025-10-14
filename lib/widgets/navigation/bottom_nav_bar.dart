import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/email_provider.dart';

class BottomNavBar extends StatefulWidget {
  final Function(int) onTabSelected;

  const BottomNavBar({
    super.key,
    required this.onTabSelected,
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
    widget.onTabSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final emailProvider = Provider.of<EmailProvider>(context);
    final unreadCount = emailProvider.allEmails.where((email) => !email.isRead).length;

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
          backgroundColor: Colors.transparent,
        ),

        // Starred/Important Tab
        BottomNavigationBarItem(
          icon: const Icon(Icons.star_border),
          activeIcon: const Icon(Icons.star),
          label: 'Important',
        ),

        // Sent Tab
        BottomNavigationBarItem(
          icon: const Icon(Icons.send),
          label: 'Sent',
        ),

        // Categories Tab
        BottomNavigationBarItem(
          icon: const Icon(Icons.category_outlined),
          activeIcon: const Icon(Icons.category),
          label: 'Categories',
        ),

        // Settings Tab
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings_outlined),
          activeIcon: const Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}