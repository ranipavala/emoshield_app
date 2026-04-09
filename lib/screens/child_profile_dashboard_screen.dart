import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app/app_router.dart';

class ChildProfileDashboardScreen extends StatelessWidget {
  const ChildProfileDashboardScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.splash,
      (route) => false,
    );
  }

  Widget _dashboardButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE7B53C),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          onPressed: onTap,
          child: Row(
            children: [
              Icon(icon, size: 30, color: Colors.black),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7ECFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/images/emoshield_logo.png',
                  height: 34,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, _) => const Text(
                    'EmoShield',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Profile Dashboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFCC66CC), width: 1.5),
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 46, color: Colors.red),
                ),
              ),

              const SizedBox(height: 28),

              _dashboardButton(
                icon: Icons.switch_account,
                label: 'Switch Profile',
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRouter.profileSelect,
                    (route) => false,
                  );
                },
              ),
              _dashboardButton(
                icon: Icons.logout,
                label: 'Log Out',
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}