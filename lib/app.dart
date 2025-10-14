import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/email_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

class GmailSummarizerApp extends StatelessWidget {
  const GmailSummarizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EmailProvider()), // Add this line
      ],
      child: MaterialApp(
        title: 'Gmail Summarizer',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: Consumer<AuthProvider>(
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
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}