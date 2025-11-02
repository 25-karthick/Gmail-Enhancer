import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gmail_enhancer_final/providers/email_provider.dart';
import '../widgets/navigation/bottom_nav_bar.dart';
import '../widgets/email/email_list.dart';
import '../widgets/common/loading_indicator.dart';
import '../widgets/common/error_widget.dart';
import 'settings_screen.dart'; // 1. Import the settings screen

/// HomeScreen now acts as a container for the different tabs
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  // We only need one instance of the search controller
  final _searchController = TextEditingController();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // 2. Define the list of screens for our navigation
    _screens = [
      // Pass the *same* controller to each email-related tab
      EmailTabPage(searchController: _searchController), // Index 0: Inbox
      EmailTabPage(searchController: _searchController), // Index 1: Important
      EmailTabPage(searchController: _searchController), // Index 2: Sent
      EmailTabPage(searchController: _searchController), // Index 3: Categories
      const SettingsScreen(), // Index 4: Settings
    ];
  }

  void _onSearchChanged() {
    // This listener will work regardless of which tab is active
    Provider.of<EmailProvider>(context, listen: false)
        .setSearchQuery(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    // Only update the email provider's category if the tab is email-related
    if (index < 4) {
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
        // TODO: Implement 'Sent' logic. For now, defaults to 'All'.
          category = 'All';
          break;
        case 3: // Categories
        // TODO: Implement 'Categories' logic. For now, defaults to 'All'.
          category = 'All';
          break;
      }
      // Set the category filter
      emailProvider.setCategory(category);
    }

    // Update the UI to show the correct screen
    setState(() {
      _currentTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 3. The body is an IndexedStack.
      // This preserves the state of each tab (like scroll position)
      // when you switch between them.
      body: IndexedStack(
        index: _currentTabIndex,
        children: _screens,
      ),
      // The BottomNavBar is the main navigation
      bottomNavigationBar: BottomNavBar(
        onTabSelected: _onTabSelected,
      ),
    );
  }
}

/// A dedicated widget for the Email tabs (Inbox, Important, etc.)
/// This contains its own Scaffold, AppBar, and FAB, as SettingsScreen has its own.
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
          // Search Bar
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
          // Email List Area
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

  /// Builds the body content based on the EmailProvider's state
  Widget _buildEmailList() {
    // Use a Consumer here to rebuild *only* this part when emails change
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

  /// Shows a message when no emails are found
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
