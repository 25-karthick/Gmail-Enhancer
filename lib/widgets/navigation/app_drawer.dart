import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/email_provider.dart';
import '../../../models/category_model.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final emailProvider = Provider.of<EmailProvider>(context);

    final categories = CategoryManager.getDefaultCategories();

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(authProvider.user?.displayName ?? 'User'),
            accountEmail: Text(authProvider.user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundImage: authProvider.user?.photoURL != null
                  ? NetworkImage(authProvider.user!.photoURL!)
                  : null,
              child: authProvider.user?.photoURL == null
                  ? const Icon(Icons.person)
                  : null,
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ...categories.map((category) {
                  final emailCount = emailProvider.allEmails
                      .where((email) => email.category == category.name)
                      .length;

                  return ListTile(
                    leading: Text(category.icon),
                    title: Text(category.name),
                    trailing: Chip(
                      label: Text(emailCount.toString()),
                      backgroundColor: category.color.withOpacity(0.2),
                    ),
                    onTap: () {
                      emailProvider.setCategory(category.name);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () {
              authProvider.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}