import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  Future<void> _loginParent() async {
    if (_isLoading) return;

    final email = emailController.text.trim();
    final password = passController.text; // keep raw password to avoid accidental credential mutation

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorText = 'Please enter email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRouter.profileSelect);
    } on FirebaseAuthException catch (e) {
      debugPrint('[Login] FirebaseAuthException code=${e.code}, message=${e.message}');

      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'No account found for this email.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          msg = 'Incorrect email or password.';
          break;
        case 'invalid-email':
          msg = 'Please enter a valid email.';
          break;
        case 'too-many-requests':
          msg = 'Too many attempts. Please try again later.';
          break;
        case 'user-disabled':
          msg = 'This account has been disabled.';
          break;
        case 'network-request-failed':
          msg = 'Network error. Check your connection and try again.';
          break;
        case 'operation-not-allowed':
          msg = 'Email/password sign-in is not enabled in Firebase.';
          break;
        default:
          msg = e.message?.trim().isNotEmpty == true
              ? e.message!.trim()
              : 'Login failed.';
      }

      if (mounted) setState(() => _errorText = msg);
    } catch (e) {
      debugPrint('[Login] Unknown error: $e');
      if (mounted) {
        setState(() => _errorText = 'Something went wrong. Please try again.');
      }
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
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                decoration: const BoxDecoration(
                  color: Color(0xFF7FB8F0),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(44),
                    topRight: Radius.circular(44),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _Label('Username Or Email'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        hintText: 'example@example.com',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _Label('Password'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: '••••••••',
                        suffixIcon: Icon(Icons.visibility_off),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                    SizedBox(
                      width: 180,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F86D6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: _isLoading ? null : _loginParent,
                        child: Text(_isLoading ? 'Logging In...' : 'Log In'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, AppRouter.parentSignup);
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}