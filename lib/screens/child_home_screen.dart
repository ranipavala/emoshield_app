import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app/app_router.dart';
import 'parent_home_screen.dart';
import 'games_screen.dart';
import 'progress_report_screen.dart';

class ChildHomeScreen extends StatelessWidget {
  final String childId;
  final String childName;
  final String? avatarAsset;

  const ChildHomeScreen({
    super.key,
    required this.childId,
    required this.childName,
    this.avatarAsset,
  });

  static const _kidWelcomeArt = 'assets/images/kids homepage_playing kid.png';
  static const _joystick = 'assets/images/kids homepage_joystick.svg';
  static const _leaderboard = 'assets/images/kids homepage_leaderboard.svg';
  static const _parentsIcon = 'assets/images/kids homepage_parents icon.svg';
  static const _quoteSun = 'assets/images/kids homepage_quotes sun.svg';

  Future<String?> _showParentPasswordDialog(BuildContext context) async {
    final controller = TextEditingController();
    String? errorText;
    bool obscure = true;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Parent Access'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter parent password to continue.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      errorText: errorText,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscure = !obscure;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) {
                      setDialogState(() {
                        errorText = 'Please enter password';
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, controller.text.trim());
                  },
                  child: const Text('Enter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openParentHome(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final enteredPassword = await _showParentPasswordDialog(context);
    if (enteredPassword == null) return;

    try {
      final email = user.email;
      if (email == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parent email not found.')),
        );
        return;
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: enteredPassword,
      );

      final parentDoc = await FirebaseFirestore.instance
          .collection('parents')
          .doc(user.uid)
          .get();

      final parentData = parentDoc.data();
      final parentName = parentData?['fullName'] ?? 'Parent';

      final childrenSnapshot = await FirebaseFirestore.instance
          .collection('parents')
          .doc(user.uid)
          .collection('children')
          .orderBy('createdAt')
          .get();

      final childNames = childrenSnapshot.docs
          .map((doc) => (doc.data()['name'] ?? 'Child').toString())
          .toList();

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ParentHomeScreen(
            parentName: parentName,
            childNames: childNames,
            recentEmotions: const [],
          ),
        ),
      );
    } on FirebaseAuthException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect parent password.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open parent page.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7ECFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            children: [
              Row(
                children: [
                  const _LogoPill(),
                  const Spacer(),
                  Text(
                    'Hi, $childName!',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.childProfileDashboard,
                    ),
                    child: _AvatarCircle(avatarAsset: avatarAsset),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6D66D9),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 10,
                      offset: Offset(0, 6),
                      color: Color(0x22000000),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,\n$childName!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Let’s play, learn and\nsee how you feel today.",
                            style: TextStyle(
                              color: Color(0xFFFFD24A),
                              fontWeight: FontWeight.w800,
                              fontSize: 12.8,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Image.asset(
                      _kidWelcomeArt,
                      height: 95,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, _) =>
                          const SizedBox(height: 95, width: 95),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _KidActionCard(
                      topSvg: _joystick,
                      bg: const Color(0xFFE85A75),
                      topTint: const Color(0xFFF7B2C1),
                      title: 'Start IQ\nGame',
                      subtitle:
                          'Solve fun puzzles\nwhile EmoShield\nevaluates your\nprogress.',
                      buttonText: 'Play Now',
                      onPressed: () =>
                          Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GamesScreen(
                            childId: childId,
                            childName: childName,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _KidActionCard(
                      topSvg: _leaderboard,
                      bg: const Color(0xFF6C7CFF),
                      topTint: const Color(0xFFC9CFFF),
                      title: 'View Progress',
                      subtitle:
                          'See your progress\nas of now, and\nlearn from there.',
                      buttonText: 'View Now',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProgressReportScreen(
                            childId: childId,
                            childName: childName,
                            isChildView: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4E9E2F),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 10,
                      offset: Offset(0, 6),
                      color: Color(0x22000000),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      _quoteSun,
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                      placeholderBuilder: (_) =>
                          const SizedBox(width: 56, height: 56),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        '“Life itself is the most\nwonderful fairy tale”',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                width: 190,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A000),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () => _openParentHome(context),
                  icon: SvgPicture.asset(
                    _parentsIcon,
                    width: 22,
                    height: 22,
                    placeholderBuilder: (_) =>
                        const Icon(Icons.family_restroom, size: 20),
                  ),
                  label: const Text(
                    'Parents',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoPill extends StatelessWidget {
  const _LogoPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF5AA7E6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Image.asset(
          'assets/images/emoshield_logo.png',
          height: 22,
          fit: BoxFit.contain,
          errorBuilder: (_, __, _) {
            return const Text(
              'EmoShield',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String? avatarAsset;

  const _AvatarCircle({this.avatarAsset});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFF2F86D6), width: 2),
      ),
      child: ClipOval(
        child: avatarAsset == null
            ? const Center(
                child: Icon(
                  Icons.face,
                  size: 22,
                  color: Color(0xFF2F86D6),
                ),
              )
            : Image.asset(
                avatarAsset!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, _) => const Center(
                  child: Icon(
                    Icons.face,
                    size: 22,
                    color: Color(0xFF2F86D6),
                  ),
                ),
              ),
      ),
    );
  }
}

class _KidActionCard extends StatelessWidget {
  final String topSvg;
  final Color bg;
  final Color topTint;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const _KidActionCard({
    required this.topSvg,
    required this.bg,
    required this.topTint,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 6),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: topTint,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Center(
              child: SvgPicture.asset(
                topSvg,
                width: 86,
                height: 86,
                placeholderBuilder: (_) =>
                    const SizedBox(width: 86, height: 86),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFD24A),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  width: 130,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 4,
                    ),
                    onPressed: onPressed,
                    child: Text(
                      buttonText,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}