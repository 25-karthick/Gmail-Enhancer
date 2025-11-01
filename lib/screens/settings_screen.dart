import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Shows a confirmation dialog before signing out.
  Future<void> _confirmSignOut(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final didRequestSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // Return false
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Log Out'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // Return true
              },
            ),
          ],
        );
      },
    );

    // If user confirmed (dialog returned true), proceed with sign out
    // The AuthProvider's listener will handle navigating to the LoginScreen
    if (didRequestSignOut == true && context.mounted) {
      await authProvider.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use a Consumer here so the UI updates if the user data ever changes
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final User? user = authProvider.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            children: [
              if (user != null)
                _buildUserProfile(user),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  _confirmSignOut(context);
                },
              ),
              // You can add other settings ListTiles here
              // e.g.,
              // ListTile(
              //   leading: const Icon(Icons.notifications_none),
              //   title: const Text('Notifications'),
              //   onTap: () {
              //     // Navigate to notification settings
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }

  /// A helper widget to display the user's profile info
  Widget _buildUserProfile(User user) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? Text(
              user.displayName?.isNotEmpty == true
                  ? user.displayName![0].toUpperCase()
                  : (user.email?.isNotEmpty == true
                  ? user.email![0].toUpperCase()
                  : 'U'),
              style: const TextStyle(fontSize: 24),
            )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.email!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}