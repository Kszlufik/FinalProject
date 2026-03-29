import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'auth_gate.dart';

void main() async {
  // This needs to be called before anything else when using async in main()
  // It makes sure Flutter's engine is fully ready before we do any setup
  WidgetsFlutterBinding.ensureInitialized();

  // Connect to our Firebase project using the auto-generated config
  // We have to await this because nothing will work without Firebase being ready first
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Hand the root widget to Flutter and start the app
  runApp(const PlayPalApp());
}

// The root widget of the whole app
// StatelessWidget because the app itself never changes — it just holds the setup
class PlayPalApp extends StatelessWidget {
  const PlayPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlayPal',
      // Removes the debug banner in the top right corner
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      // AuthGate decides whether to show the login screen or home screen
      // depending on whether the user is logged in or not
      home: const AuthGate(),
    );
  }
}