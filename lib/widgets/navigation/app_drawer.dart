import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/email_provider.dart';
// 1. Import the CategoryProvider to get the category list and counts
import '../../../providers/category_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. Get all required providers
    // We 'watch' AuthProvider because the header should update if the user changes.
    final authProvider = context.watch<AuthProvider>();

    // We 'watch' CategoryProvider because the list and counts must update.
    final categoryProvider = context.watch<CategoryProvider>();

    // We 'read' EmailProvider because we only need its 'setCategory' function
    // for the onTap, and we don't want to rebuild the whole drawer if emails change.
    final emailProvider = context.read<EmailProvider>();

    return Drawer(
      child: Column(
        children: [
          // User info header - this part is correct
          UserAccountsDrawerHeader(
            accountName: Text(authProvider.user?.displayName ?? 'User'),
            accountEmail: Text(authProvider.user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundImage: authProvider.user?.photoURL != null
                  ? NetworkImage(authProvider.user!.photoURL!)
                  : null,
              child: authProvider.user?.photoURL == null
                  ? const Icon(Icons.person, color: Colors.white, size: 30)
                  : null,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
            ),
          ),

          // Category List - This is the modified section
          Expanded(
            child: ListView(
              // Remove extra padding from the top of the list
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
                // 3. Iterate over the categories from the CategoryProvider
                ...categoryProvider.categories.map((category) {
                  // 4. NO MORE MANUAL CALCULATION.
                  // The 'category.count' is now provided and always correct
                  // thanks to the ChangeNotifierProxyProvider.

                  return ListTile(
                    leading: Text(
                      category.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    title: Text(category.name),
                    trailing: Chip(
                      label: Text(
                        category.count.toString(), // 5. Use the provider's count
                        style: TextStyle(
                          // Make text dark or light based on chip color
                          color: category.color.computeLuminance() > 0.5
                              ? Colors.black87
                              : Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: category.color.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      visualDensity: VisualDensity.compact,
                    ),
                    onTap: () {
                      // 6. Call the provider to set the filter
                      emailProvider.setCategory(category.name);
                      // Close the drawer
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),

          // Sign Out button - this part is correct
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              // Call AuthProvider to sign out
              authProvider.signOut();
              // Close the drawer
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
