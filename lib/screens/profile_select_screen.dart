import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'child_home_screen.dart';
import 'parent_home_screen.dart';

class ProfileSelectScreen extends StatefulWidget {
  const ProfileSelectScreen({super.key});

  @override
  State<ProfileSelectScreen> createState() => _ProfileSelectScreenState();
}

class _ProfileSelectScreenState extends State<ProfileSelectScreen> {
  late final Future<_ProfileData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProfileData> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const _ProfileData(children: [], parentName: 'Parent');

    final childrenFuture = FirebaseFirestore.instance
        .collection('parents')
        .doc(user.uid)
        .collection('children')
        .orderBy('createdAt')
        .get();

    final parentFuture =
        FirebaseFirestore.instance.collection('parents').doc(user.uid).get();

    final result = await Future.wait([childrenFuture, parentFuture]);
    final childrenSnap = result[0] as QuerySnapshot<Map<String, dynamic>>;
    final parentSnap = result[1] as DocumentSnapshot<Map<String, dynamic>>;

    final children = childrenSnap.docs
        .map((doc) => {'id': doc.id, 'name': (doc.data()['name'] ?? 'Child').toString()})
        .toList();

    final parentName = (parentSnap.data()?['fullName'] ?? 'Parent').toString();

    return _ProfileData(children: children, parentName: parentName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7ECFF),
      body: SafeArea(
        child: FutureBuilder<_ProfileData>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snap.data!;
            final children = data.children;
            final parentName = data.parentName;
            final childNames = children.map((e) => e['name'] as String).toList();

            final c1Name = children.isNotEmpty ? children[0]['name'] as String : null;
            final c1Id = children.isNotEmpty ? children[0]['id'] as String : null;

            final c2Name = children.length > 1 ? children[1]['name'] as String : null;
            final c2Id = children.length > 1 ? children[1]['id'] as String : null;

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
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ProfileButton(
                    label: c1Name?.toUpperCase() ?? 'CHILD 1',
                    enabled: c1Name != null,
                    onPressed: c1Name == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChildHomeScreen(
                                  childId: c1Id!,
                                  childName: c1Name,
                                ),
                              ),
                            );
                          },
                  ),
                  const SizedBox(height: 18),
                  _ProfileButton(
                    label: c2Name?.toUpperCase() ?? 'CHILD 2',
                    enabled: c2Name != null,
                    onPressed: c2Name == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChildHomeScreen(
                                  childId: c2Id!,
                                  childName: c2Name,
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

class _ProfileData {
  final List<Map<String, dynamic>> children;
  final String parentName;

  const _ProfileData({
    required this.children,
    required this.parentName,
  });
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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