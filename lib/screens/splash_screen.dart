import 'package:flutter/material.dart';
import '../app/app_router.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background
            Container(color: const Color(0xFFD7ECFF)),

            // Simple clouds (no assets needed)
            Positioned(
              top: 40,
              right: -30,
              child: _CloudBubble(width: 140, height: 70),
            ),
            Positioned(
              top: 110,
              left: -40,
              child: _CloudBubble(width: 120, height: 60),
            ),

            // Main content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hero illustration (from Figma)
                    Image.asset(
                      'assets/images/splash_hero.png',
                      height: 260,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const SizedBox(height: 260);
                      },
                    ),

                    const SizedBox(height: 18),

                    // Logo banner (from Figma)
                    Image.asset(
                      'assets/images/emoshield_logo.png',
                      height: 56,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Text(
                          'EmoShield',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Emotion Guardian for Kids',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 22),

                    // Get Started Button (white rounded)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, AppRouter.login);
                        },
                        child: const Text('GET STARTED'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudBubble extends StatelessWidget {
  final double width;
  final double height;

  const _CloudBubble({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.9,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}