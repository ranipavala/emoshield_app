import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'child_home_screen.dart';
import 'parent_home_screen.dart';

class ProfileSelectScreen extends StatelessWidget {
  const ProfileSelectScreen({super.key});

  Future<List<Map<String, dynamic>>> loadChildren() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('parents')
        .doc(user.uid)
        .collection('children')
        .orderBy('createdAt')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['name'] ?? 'Child',
      };
    }).toList();
  }

  Future<String> loadParentName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Parent';

    final doc = await FirebaseFirestore.instance
        .collection('parents')
        .doc(user.uid)
        .get();

    final data = doc.data();
    return data?['fullName'] ?? 'Parent';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7ECFF),
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([
            loadChildren(),
            loadParentName(),
          ]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final children = snapshot.data![0] as List<Map<String, dynamic>>;
            final parentName = snapshot.data![1] as String;

            final String? child1Name =
                children.isNotEmpty ? children[0]['name'] as String : null;
            final String? child2Name =
                children.length > 1 ? children[1]['name'] as String : null;

            final childNames =
                children.map((child) => child['name'] as String).toList();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  Image.asset(
                    'assets/images/splash screen kid parent.png',
                    height: 210,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, _) => const SizedBox(height: 210),
                  ),

                  const SizedBox(height: 10),

                  Image.asset(
                    'assets/images/emoshield_logo.png',
                    height: 55,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, _) => const Text(
                      'EmoShield',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _ProfileButton(
                    label: child1Name?.toUpperCase() ?? 'CHILD 1',
                    enabled: child1Name != null,
                    onPressed: child1Name == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChildHomeScreen(
                                  childName: child1Name,
                                ),
                              ),
                            );
                          },
                  ),

                  const SizedBox(height: 18),

                  _ProfileButton(
                    label: child2Name?.toUpperCase() ?? 'CHILD 2',
                    enabled: child2Name != null,
                    onPressed: child2Name == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChildHomeScreen(
                                  childName: child2Name,
                                ),
                              ),
                            );
                          },
                  ),

                  const SizedBox(height: 18),

                  _ProfileButton(
                    label: 'PARENT',
                    enabled: true,
                    onPressed: () {
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
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  const _ProfileButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              enabled ? const Color(0xFF1E88F5) : const Color(0xFF7FB8F0),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}