import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/email_provider.dart';
import '../widgets/navigation/bottom_nav_bar.dart';
import '../widgets/email/email_list.dart';
import '../widgets/common/loading_indicator.dart';
import '../widgets/common/error_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  int _currentTabIndex = 0;
  String _currentCategory = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    Provider.of<EmailProvider>(context, listen: false)
        .setSearchQuery(_searchController.text);
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentTabIndex = index;
    });

    final emailProvider = Provider.of<EmailProvider>(context, listen: false);

    switch (index) {
      case 0: // Inbox - All emails
        emailProvider.setCategory('All');
        break;
      case 1: // Important - Jobs category
        emailProvider.setCategory('Jobs');
        break;
      case 2: // Sent (you can implement sent emails logic)
        emailProvider.setCategory('All');
        break;
      case 3: // Categories - Show all
        emailProvider.setCategory('All');
        break;
      case 4: // Settings
      // Navigate to settings or handle settings
        break;
    }
  }

  void _onCategorySelected(String category) {
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);
    emailProvider.setCategory(category);
  }

  Widget _buildCurrentScreen() {
    final emailProvider = Provider.of<EmailProvider>(context);

    if (emailProvider.isLoading) {
      return const LoadingIndicator();
    } else if (emailProvider.error != null) {
      return CustomErrorWidget(
        message: emailProvider.error!,
        onRetry: () => emailProvider.refreshEmails(),
      );
    } else if (emailProvider.emails.isEmpty) {
      return _buildEmptyState();
    } else {
      return EmailList(emails: emailProvider.emails);
    }
  }

  Widget _buildEmptyState() {
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
            _getEmptyStateMessage(),
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getEmptyStateMessage() {
    switch (_currentTabIndex) {
      case 0:
        return 'Your inbox is empty';
      case 1:
        return 'No important emails';
      case 2:
        return 'No sent emails';
      case 3:
        return 'No categorized emails';
      default:
        return 'No emails available';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
              controller: _searchController,
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
          // Email List
          Expanded(
            child: _buildCurrentScreen(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        onTabSelected: _onTabSelected,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Provider.of<EmailProvider>(context, listen: false)
            .refreshEmails(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}