import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/camera_test_screen.dart';
import 'app/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const EmoShieldApp());
}

class EmoShieldApp extends StatelessWidget {
  const EmoShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EmoShield',
      theme: AppTheme.light(),
      home: const CameraTestScreen(),
    );
  }
}