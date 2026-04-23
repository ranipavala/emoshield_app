import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app/app_router.dart';

class ParentProfileDashboardScreen extends StatefulWidget {
  const ParentProfileDashboardScreen({super.key});

  @override
  State<ParentProfileDashboardScreen> createState() =>
      _ParentProfileDashboardScreenState();
}

class _ParentProfileDashboardScreenState extends State<ParentProfileDashboardScreen> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic> _parentData = const {};
  String _displayName = 'Parent';

  User? get _user => FirebaseAuth.instance.currentUser;
  String? get _uid => _user?.uid;

  DocumentReference<Map<String, dynamic>> _parentRef(String uid) {
    return FirebaseFirestore.instance.collection('parents').doc(uid);
  }

  Future<void> _loadParentData() async {
    final uid = _uid;
    if (uid == null) {
      setState(() {
        _loading = false;
        _error = 'No authenticated parent user found.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final snap = await _parentRef(uid).get();
      final data = snap.data() ?? <String, dynamic>{};

      setState(() {
        _parentData = data;
        _displayName = (data['fullName'] ?? 'Parent').toString();
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Failed to load profile data.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadParentData();
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.splash,
      (route) => false,
    );
  }

  void _switchProfile() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.profileSelect,
      (route) => false,
    );
  }

  Future<void> _showEditProfileDialog() async {
    final uid = _uid;
    final user = _user;
    if (uid == null || user == null) return;

    final fullNameController =
        TextEditingController(text: (_parentData['fullName'] ?? '').toString());
    final emailController = TextEditingController(
      text: (_parentData['email'] ?? user.email ?? '').toString(),
    );
    final mobileController = TextEditingController(
      text: (_parentData['mobile'] ?? '').toString(),
    );

    bool saving = false;
    String? dialogError;

    await showDialog<void>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> save() async {
              final newFullName = fullNameController.text.trim();
              final newEmail = emailController.text.trim();
              final currentEmail = (user.email ?? '').trim();

              if (newFullName.isEmpty) {
                setLocalState(() => dialogError = 'Name cannot be empty.');
                return;
              }
              if (newEmail.isEmpty || !newEmail.contains('@')) {
                setLocalState(() => dialogError = 'Enter a valid email.');
                return;
              }

              setLocalState(() {
                saving = true;
                dialogError = null;
              });

              try {
                // Update Auth email if changed.
                if (newEmail.toLowerCase() != currentEmail.toLowerCase()) {
                  await user.updateEmail(newEmail);
                }

                // Update Firestore profile; phone remains non-editable.
                await _parentRef(uid).set({
                  'fullName': newFullName,
                  'email': newEmail,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                await _loadParentData();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully.')),
                );
              } on FirebaseAuthException catch (e) {
                String message = 'Failed to update profile.';
                if (e.code == 'requires-recent-login') {
                  message =
                      'For security, please log in again before changing email.';
                } else if (e.code == 'email-already-in-use') {
                  message = 'This email is already used by another account.';
                } else if (e.code == 'invalid-email') {
                  message = 'Invalid email format.';
                }

                setLocalState(() {
                  saving = false;
                  dialogError = message;
                });
              } catch (_) {
                setLocalState(() {
                  saving = false;
                  dialogError = 'Failed to update profile. Please try again.';
                });
              }
            }

            return AlertDialog(
              title: const Text('Edit Parent Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: mobileController,
                      readOnly: true,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (Read Only)',
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        dialogError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : save,
                  child: Text(saving ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final user = _user;
    if (user == null) return;

    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();

    bool saving = false;
    String? dialogError;

    await showDialog<void>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> save() async {
              final pass = newPassword.text.trim();
              final confirm = confirmPassword.text.trim();

              if (pass.length < 6) {
                setLocalState(() => dialogError = 'Password must be at least 6 characters.');
                return;
              }
              if (pass != confirm) {
                setLocalState(() => dialogError = 'Passwords do not match.');
                return;
              }

              setLocalState(() {
                saving = true;
                dialogError = null;
              });

              try {
                await user.updatePassword(pass);

                if (!mounted) return;
                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated successfully.')),
                );
              } on FirebaseAuthException catch (e) {
                String message = 'Failed to update password.';
                if (e.code == 'requires-recent-login') {
                  message =
                      'For security, please log in again before changing password.';
                } else if (e.code == 'weak-password') {
                  message = 'Password is too weak.';
                }

                setLocalState(() {
                  saving = false;
                  dialogError = message;
                });
              } catch (_) {
                setLocalState(() {
                  saving = false;
                  dialogError = 'Failed to update password. Please try again.';
                });
              }
            }

            return AlertDialog(
              title: const Text('Change Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newPassword,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New Password'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmPassword,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm Password'),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      dialogError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : save,
                  child: Text(saving ? 'Updating...' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openChildrenManagement() async {
    final uid = _uid;
    if (uid == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChildManagementScreen(parentId: uid),
      ),
    );
  }

  void _goBackHome() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.parentHome,
      (route) => false,
    );
  }

  Widget _dashboardButton({
    required String iconPath,
    required String label,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 62,
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

  Widget _homeBottomButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2F86D6),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _goBackHome,
        icon: const Icon(Icons.home_filled, color: Colors.white),
        label: const Text(
          'Back to Homepage',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Colors.white,
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'assets/images/emoshield_logo.png',
                        height: 34,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Text(
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
                    const SizedBox(height: 6),
                    Text(
                      _displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFCC66CC),
                          width: 1.5,
                        ),
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
                    const SizedBox(height: 18),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    _dashboardButton(
                      iconPath: 'assets/images/profile dash_edit profile.svg',
                      label: 'Edit Profile',
                      onTap: _showEditProfileDialog,
                    ),
                    _dashboardButton(
                      iconPath: 'assets/images/profile dash_change pass.svg',
                      label: 'Change Password',
                      onTap: _showChangePasswordDialog,
                    ),
                    _dashboardButton(
                      iconPath: 'assets/images/profile dash_children.svg',
                      label: 'Manage Children',
                      onTap: _openChildrenManagement,
                    ),
                    _dashboardButton(
                      iconPath: 'assets/images/profile dash_children.svg',
                      label: 'Switch Profile',
                      onTap: _switchProfile,
                    ),
                    _dashboardButton(
                      iconPath: 'assets/images/profile dash_log out.svg',
                      label: 'Log Out',
                      onTap: () => _logout(context),
                    ),
                    const Spacer(),
                    // Homepage action intentionally bottom-most.
                    _homeBottomButton(),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ChildManagementScreen extends StatelessWidget {
  final String parentId;

  const _ChildManagementScreen({required this.parentId});

  CollectionReference<Map<String, dynamic>> get _childrenRef =>
      FirebaseFirestore.instance
          .collection('parents')
          .doc(parentId)
          .collection('children');

  Future<void> _showEditChildDialog(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> childDoc,
  ) async {
    final data = childDoc.data() ?? <String, dynamic>{};

    final nameController = TextEditingController(text: (data['name'] ?? '').toString());
    final dobController = TextEditingController(text: (data['dob'] ?? '').toString());
    String gender = (data['gender'] ?? 'Male').toString();

    bool saving = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> save() async {
              final name = nameController.text.trim();
              final dob = dobController.text.trim();

              if (name.isEmpty || dob.isEmpty) {
                setLocalState(() => errorText = 'Name and DOB are required.');
                return;
              }

              setLocalState(() {
                saving = true;
                errorText = null;
              });

              try {
                await childDoc.reference.set({
                  'name': name,
                  'dob': dob,
                  'gender': gender,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (!context.mounted) return;
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Child info updated.')),
                );
              } catch (_) {
                setLocalState(() {
                  saving = false;
                  errorText = 'Failed to update child info.';
                });
              }
            }

            return AlertDialog(
              title: const Text('Edit Child Info'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Child Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dobController,
                      decoration: const InputDecoration(labelText: 'Date of Birth'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setLocalState(() => gender = value);
                      },
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : save,
                  child: Text(saving ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showChangePinDialog(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> childDoc,
  ) async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    bool saving = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> save() async {
              final pin = pinController.text.trim();
              final confirm = confirmController.text.trim();

              if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
                setLocalState(() => errorText = 'PIN must be exactly 4 digits.');
                return;
              }
              if (pin != confirm) {
                setLocalState(() => errorText = 'PIN confirmation does not match.');
                return;
              }

              setLocalState(() {
                saving = true;
                errorText = null;
              });

              try {
                await childDoc.reference.set({
                  'pin': pin,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (!context.mounted) return;
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Child PIN updated.')),
                );
              } catch (_) {
                setLocalState(() {
                  saving = false;
                  errorText = 'Failed to update PIN.';
                });
              }
            }

            return AlertDialog(
              title: const Text('Change Child PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New 4-digit PIN'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm PIN'),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : save,
                  child: Text(saving ? 'Updating...' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCollection(CollectionReference<Map<String, dynamic>> colRef) async {
    final snap = await colRef.get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _deleteChildCompletely(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> childDoc,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Child Profile'),
          content: const Text(
            'This will remove child info and related progress/reports. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final childRef = childDoc.reference;

      await _deleteCollection(childRef.collection('gameProgress'));

      final gameSessionsRef = childRef.collection('gameSessions');
      final sessions = await gameSessionsRef.get();
      for (final session in sessions.docs) {
        await _deleteCollection(session.reference.collection('emotionReadings'));
        await session.reference.delete();
      }

      await _deleteCollection(childRef.collection('emotionalReports'));
      await childRef.delete();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Child profile deleted.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete child profile.')),
      );
    }
  }

  Widget _childCard(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> childDoc,
  ) {
    final data = childDoc.data() ?? <String, dynamic>{};
    final name = (data['name'] ?? 'Child').toString();
    final dob = (data['dob'] ?? '-').toString();
    final gender = (data['gender'] ?? '-').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 4),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 4),
          Text('DOB: $dob', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('Gender: $gender', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showEditChildDialog(context, childDoc),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Info'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showChangePinDialog(context, childDoc),
                icon: const Icon(Icons.pin),
                label: const Text('Change PIN'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _deleteChildCompletely(context, childDoc),
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD7ECFF),
        elevation: 0,
        title: const Text(
          'Manage Children',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _childrenRef.orderBy('createdAt').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'No children found.\nPlease add children first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              );
            }

            return ListView(
              children: docs.map((doc) => _childCard(context, doc)).toList(),
            );
          },
        ),
      ),
    );
  }
}