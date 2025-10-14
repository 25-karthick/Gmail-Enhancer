import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
// Add this helper package for web and mobile auth client support
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/gmail.readonly',
      'https://www.googleapis.com/auth/gmail.modify',
    ],
  );

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web Login Flow
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider
            .addScope('https://www.googleapis.com/auth/gmail.readonly');
        googleProvider
            .addScope('https://www.googleapis.com/auth/gmail.modify');

        final UserCredential userCredential =
        await _firebaseAuth.signInWithPopup(googleProvider);

        return userCredential.user;
      } else {
        // Mobile/Desktop Login Flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          print('⚠️ Google sign-in aborted by user.');
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential =
        await _firebaseAuth.signInWithCredential(credential);

        return userCredential.user;
      }
    } on FirebaseAuthException catch (e, s) {
      print('🔥 FirebaseAuthException: ${e.code}');
      print('📩 Message: ${e.message ?? "No message provided"}');
      print('📜 Stack Trace: $s');
      return null;
    } catch (e, s) {
      print('❌ General Auth Error: $e');
      print('📜 Stack Trace: $s');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      print('✅ Signed out successfully.');
    } catch (e) {
      print('⚠️ Sign-out failed: $e');
    }
  }

  // ✅ CORRECTED: Gmail Auth Client that supports BOTH mobile and web
  Future<auth.AuthClient?> getGmailAuthClient() async {
    try {
      // Get the currently signed-in user without prompting them again.
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account == null) {
        print('⚠️ No active Google account found. User may need to sign in first.');
        return null;
      }

      // This extension method works for both mobile and web platforms.
      final auth.AuthClient? client = await _googleSignIn.authenticatedClient();

      if (client != null) {
        print('✅ Gmail AuthClient created successfully.');
        return client;
      } else {
        print('⚠️ Failed to create authenticated client.');
        return null;
      }
    } catch (e, s) {
      print('❌ Failed to create Gmail AuthClient: $e');
      print('📜 Stack Trace: $s');
      return null;
    }
  }
}