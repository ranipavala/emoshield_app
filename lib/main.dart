import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app_router.dart';
import 'app/app_theme.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

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
      routes: AppRouter.routes,
      onGenerateInitialRoutes: (_) => [
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: AppRouter.splash),
          builder: (_) => const SplashScreen(),
        ),
      ],
    );
  }
}