import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app/app_router.dart';

class ParentProfileDashboardScreen extends StatelessWidget {
  const ParentProfileDashboardScreen({super.key});

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
    required String iconPath,
    required String label,
    required VoidCallback? onTap,
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
              SvgPicture.asset(
                iconPath,
                width: 30,
                height: 30,
                placeholderBuilder: (_) =>
                    const Icon(Icons.circle, size: 24, color: Colors.black),
              ),
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

              const SizedBox(height: 14),

              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFCC66CC), width: 1.5),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/parents homepage_profile icon.svg',
                    width: 54,
                    height: 54,
                    placeholderBuilder: (_) =>
                        const Icon(Icons.person, size: 42, color: Colors.red),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              _dashboardButton(
                iconPath: 'assets/images/profile dash_edit profile.svg',
                label: 'Edit Profile',
                onTap: () {},
              ),
              _dashboardButton(
                iconPath: 'assets/images/profile dash_change pass.svg',
                label: 'Change Password',
                onTap: () {},
              ),
              _dashboardButton(
                iconPath: 'assets/images/profile dash_children.svg',
                label: 'Children',
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRouter.profileSelect,
                    (route) => false,
                  );
                },
              ),
              _dashboardButton(
                iconPath: 'assets/images/profile dash_settings.svg',
                label: 'Settings',
                onTap: () {},
              ),
              _dashboardButton(
                iconPath: 'assets/images/profile dash_log out.svg',
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