import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PlayPalApp());
}

class PlayPalApp extends StatelessWidget {
  const PlayPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlayPal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: HomeScreen(),
    );
  }
}
