import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

// Listens to Firebase auth state and routes to the correct screen automatically
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // authStateChanges emits a new value whenever login state changes
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // User is logged in — show home screen
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // No user — show login screen
        return const LoginScreen();
      },
    );
  }
}