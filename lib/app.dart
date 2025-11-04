import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/email_provider.dart';
import 'providers/category_provider.dart'; // 1. Import
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

class GmailSummarizerApp extends StatelessWidget {
  const GmailSummarizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 2. All providers declared
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EmailProvider()),

        // 3. This links CategoryProvider to EmailProvider
        ChangeNotifierProxyProvider<EmailProvider, CategoryProvider>(
          create: (_) => CategoryProvider(),
          update: (_, emailProvider, previousCategoryProvider) {
            // This runs whenever EmailProvider changes
            previousCategoryProvider?.updateCategoryCounts(emailProvider.allEmails);
            return previousCategoryProvider!;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Gmail Summarizer',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: const AuthWrapper(), // 4. Use a simple wrapper
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// 5. This wrapper cleans up the logic
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return authProvider.user == null
            ? const LoginScreen()
            : const HomeScreen();
      },
    );
  }
}
