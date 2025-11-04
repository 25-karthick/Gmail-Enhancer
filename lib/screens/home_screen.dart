import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gmail_enhancer_final/providers/email_provider.dart';
import '../widgets/navigation/bottom_nav_bar.dart';
import '../widgets/email/email_list.dart';
import '../widgets/common/loading_indicator.dart';
import '../widgets/common/error_widget.dart';
import 'settings_screen.dart';
import 'reminders_screen.dart'; // 1. Import the new screen

/// HomeScreen now acts as a container for the different tabs
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  final _searchController = TextEditingController();
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // 2. Define the list of screens
    _screens = [
      EmailTabPage(searchController: _searchController), // Index 0: Inbox
      EmailTabPage(searchController: _searchController), // Index 1: Important
      EmailTabPage(searchController: _searchController), // Index 2: Sent
      const RemindersScreen(),                           // 3. ✅ Index 3: Reminders
      const SettingsScreen(),                            // 4. Index 4: Settings
    ];
  }

  void _onSearchChanged() {
    Provider.of<EmailProvider>(context, listen: false)
        .setSearchQuery(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    // 5. ✅ Only set category for email-related tabs (index 0, 1, 2)
    if (index < 3) {
      final emailProvider = Provider.of<EmailProvider>(context, listen: false);
      String category = 'All'; // Default
      switch (index) {
        case 0: // Inbox
          category = 'All';
          break;
        case 1: // Important
          category = 'Jobs'; // As defined in your original logic
          break;
        case 2: // Sent
        // TODO: Implement 'Sent' logic.
          category = 'All';
          break;
      }
      emailProvider.setCategory(category);
    }

    // Index 3 (Reminders) and 4 (Settings) are handled by the IndexedStack
    // and don't require any special logic here.

    setState(() {
      _currentTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTabIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        onTabSelected: _onTabSelected,
      ),
    );
  }
}


// --- This EmailTabPage widget remains unchanged ---
// (Paste your existing EmailTabPage widget code here)

/// A dedicated widget for the Email tabs (Inbox, Important, etc.)
class EmailTabPage extends StatelessWidget {
  final TextEditingController searchController;
  const EmailTabPage({super.key, required this.searchController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gmail Summarizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<EmailProvider>(context, listen: false)
                .refreshEmails(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search emails...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: _buildEmailList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Provider.of<EmailProvider>(context, listen: false)
            .refreshEmails(),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildEmailList() {
    return Consumer<EmailProvider>(
      builder: (context, emailProvider, child) {
        if (emailProvider.isLoading) {
          return const LoadingIndicator();
        }
        if (emailProvider.error != null) {
          return CustomErrorWidget(
            message: emailProvider.error!,
            onRetry: () => emailProvider.refreshEmails(),
          );
        }
        if (emailProvider.emails.isEmpty) {
          return _buildEmptyState(emailProvider.selectedCategory);
        }
        return EmailList(emails: emailProvider.emails);
      },
    );
  }

  Widget _buildEmptyState(String selectedCategory) {
    final message = selectedCategory == 'All'
        ? 'Your inbox is empty'
        : 'No emails in $selectedCategory';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.email_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No emails found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}