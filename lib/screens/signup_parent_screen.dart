import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app/app_router.dart';


class ParentSignUpScreen extends StatefulWidget {
  const ParentSignUpScreen({super.key});

  @override
  State<ParentSignUpScreen> createState() => _ParentSignUpScreenState();
}

class _ParentSignUpScreenState extends State<ParentSignUpScreen> {
  final fullName = TextEditingController();
  final email = TextEditingController();
  final mobile = TextEditingController();
  final dob = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  bool consentChecked = false;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    fullName.dispose();
    email.dispose();
    mobile.dispose();
    dob.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _signUpParent() async {
    if (_isLoading) return;

    if (!consentChecked) {
      setState(() => _errorText = 'Please tick the consent box to continue.');
      return;
    }

    final emailText = email.text.trim();
    final passText = password.text.trim();
    final confirmText = confirm.text.trim();

    if (fullName.text.trim().isEmpty ||
        emailText.isEmpty ||
        mobile.text.trim().isEmpty ||
        dob.text.trim().isEmpty ||
        passText.isEmpty ||
        confirmText.isEmpty) {
      setState(() => _errorText = 'Please fill in all fields.');
      return;
    }

    if (passText != confirmText) {
      setState(() => _errorText = 'Passwords do not match.');
      return;
    }

    if (passText.length < 6) {
      setState(() => _errorText = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: emailText,
  password: passText,
);

final uid = cred.user!.uid;

await FirebaseFirestore.instance.collection('parents').doc(uid).set({
  'fullName': fullName.text.trim(),
  'email': emailText,
  'mobile': mobile.text.trim(),
  'dob': dob.text.trim(),
  'consentGiven': consentChecked,
  'createdAt': FieldValue.serverTimestamp(),
});

      if (!mounted) return;

      // ✅ Step 1 done: parent auth account created successfully
      Navigator.pushReplacementNamed(context, AppRouter.kidsRegistration);
    } on FirebaseAuthException catch (e) {
      String msg = 'Sign up failed. Please try again.';
      if (e.code == 'email-already-in-use') msg = 'This email is already registered.';
      if (e.code == 'invalid-email') msg = 'Please enter a valid email address.';
      if (e.code == 'weak-password') msg = 'Password is too weak (min 6 characters).';

      setState(() => _errorText = msg);
    } catch (_) {
      setState(() => _errorText = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(color: const Color(0xFFD7ECFF)),

            // Logo banner at top
            Positioned(
              top: 18,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset(
                  'assets/images/emoshield_logo.png',
                  height: 54,
                  errorBuilder: (_, __, ___) {
                    return const Text(
                      'EmoShield',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                    );
                  },
                ),
              ),
            ),

            // Blue rounded form panel
            Positioned(
              top: 98,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF7FB8F0),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(44),
                    topRight: Radius.circular(44),
                  ),
                ),
                child: ListView(
                  children: [
                    const SizedBox(height: 6),

                    _FieldLabel('Full Name'),
                    TextField(
                      controller: fullName,
                      decoration: const InputDecoration(hintText: 'EXAMPLE A / EXAMPLE'),
                    ),
                    const SizedBox(height: 14),

                    _FieldLabel('Email'),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'example@example.com'),
                    ),
                    const SizedBox(height: 14),

                    _FieldLabel('Mobile Number'),
                    TextField(
                      controller: mobile,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: '+6011 -1234 5678'),
                    ),
                    const SizedBox(height: 14),

                    _FieldLabel('Date Of Birth'),
                    TextField(
                      controller: dob,
                      decoration: const InputDecoration(hintText: 'DD / MM / YYYY'),
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                          initialDate: DateTime(2000),
                        );
                        if (picked != null) {
                          dob.text = '${picked.day.toString().padLeft(2, '0')} / '
                              '${picked.month.toString().padLeft(2, '0')} / '
                              '${picked.year}';
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    _FieldLabel('Password'),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: '••••••••'),
                    ),
                    const SizedBox(height: 14),

                    _FieldLabel('Confirm Password'),
                    TextField(
                      controller: confirm,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: '••••••••'),
                    ),
                    const SizedBox(height: 14),

                    // ✅ Consent checkbox BEFORE kids registration
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: consentChecked,
                            onChanged: _isLoading
                                ? null
                                : (v) => setState(() => consentChecked = v ?? false),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'I consent to the collection and processing of my child’s emotional data '
                              'for wellbeing monitoring and reporting, and I agree to the Terms of Use '
                              'and Privacy Policy.',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ✅ Error text (if any)
                    if (_errorText != null) ...[
                      Text(
                        _errorText!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // ✅ Continue button -> Firebase Auth signup
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (consentChecked && !_isLoading)
                              ? const Color(0xFF2F86D6)
                              : Colors.grey.shade500,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: (consentChecked && !_isLoading) ? _signUpParent : null,
                        child: Text(
                          _isLoading ? 'Creating account...' : 'Continue',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Center(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => Navigator.pushReplacementNamed(context, AppRouter.login),
                        child: const Text(
                          'Already have an account?  Log In',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    );
  }
}