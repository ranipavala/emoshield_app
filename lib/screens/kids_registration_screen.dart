import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app/app_router.dart';

class KidsRegistrationScreen extends StatefulWidget {
  const KidsRegistrationScreen({super.key});

  @override
  State<KidsRegistrationScreen> createState() => _KidsRegistrationScreenState();
}

class _KidsRegistrationScreenState extends State<KidsRegistrationScreen> {
  int kidsCount = 1; // min 1, max 2

  final kid1Name = TextEditingController();
  final kid1Dob = TextEditingController();
  final kid1Pin = TextEditingController();
  final kid1ConfirmPin = TextEditingController();
  String kid1Gender = 'Male';

  final kid2Name = TextEditingController();
  final kid2Dob = TextEditingController();
  final kid2Pin = TextEditingController();
  final kid2ConfirmPin = TextEditingController();
  String kid2Gender = 'Male';

  bool _isSaving = false;
  String? _errorText;

  @override
  void dispose() {
    kid1Name.dispose();
    kid1Dob.dispose();
    kid1Pin.dispose();
    kid1ConfirmPin.dispose();

    kid2Name.dispose();
    kid2Dob.dispose();
    kid2Pin.dispose();
    kid2ConfirmPin.dispose();

    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
      initialDate: DateTime(2018),
    );
    if (picked != null) {
      controller.text =
          '${picked.day.toString().padLeft(2, '0')} / ${picked.month.toString().padLeft(2, '0')} / ${picked.year}';
    }
  }

  bool _isValidPin(String pin) {
    final pinRegex = RegExp(r'^\d{4}$');
    return pinRegex.hasMatch(pin);
  }

  Future<void> _saveChildren() async {
    if (_isSaving) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _errorText = 'Parent not authenticated.');
      return;
    }

    // Child 1 validation
    if (kid1Name.text.trim().isEmpty || kid1Dob.text.trim().isEmpty) {
      setState(() => _errorText = 'Please complete Child 1 details.');
      return;
    }

    if (!_isValidPin(kid1Pin.text.trim())) {
      setState(() => _errorText = 'Child 1 PIN must be exactly 4 digits.');
      return;
    }

    if (kid1Pin.text.trim() != kid1ConfirmPin.text.trim()) {
      setState(() => _errorText = 'Child 1 PIN and confirmation PIN do not match.');
      return;
    }

    // Child 2 validation (only if 2 kids)
    if (kidsCount == 2) {
      if (kid2Name.text.trim().isEmpty || kid2Dob.text.trim().isEmpty) {
        setState(() => _errorText = 'Please complete Child 2 details.');
        return;
      }

      if (!_isValidPin(kid2Pin.text.trim())) {
        setState(() => _errorText = 'Child 2 PIN must be exactly 4 digits.');
        return;
      }

      if (kid2Pin.text.trim() != kid2ConfirmPin.text.trim()) {
        setState(() => _errorText = 'Child 2 PIN and confirmation PIN do not match.');
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final parentRef =
          FirebaseFirestore.instance.collection('parents').doc(user.uid);

      // Save Child 1
      await parentRef.collection('children').add({
        'name': kid1Name.text.trim(),
        'dob': kid1Dob.text.trim(),
        'gender': kid1Gender,
        'pin': kid1Pin.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Save Child 2
      if (kidsCount == 2) {
        await parentRef.collection('children').add({
          'name': kid2Name.text.trim(),
          'dob': kid2Dob.text.trim(),
          'gender': kid2Gender,
          'pin': kid2Pin.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRouter.profileSelect);
    } catch (e) {
      setState(() => _errorText = 'Failed to save children. Try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _kidCard({
    required String title,
    required TextEditingController nameController,
    required TextEditingController dobController,
    required TextEditingController pinController,
    required TextEditingController confirmPinController,
    required String genderValue,
    required Function(String?) onGenderChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(191),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Enter child full name',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Text('Date Of Birth', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: dobController,
            readOnly: true,
            decoration: const InputDecoration(
              hintText: 'DD / MM / YYYY',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ),
            onTap: () => _pickDate(dobController),
          ),
          const SizedBox(height: 12),

          const Text('Gender', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: genderValue,
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
            ],
            onChanged: onGenderChanged,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Text('4-Digit PIN', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: const InputDecoration(
              hintText: 'Enter 4-digit PIN',
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Text('Confirm 4-Digit PIN',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: confirmPinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: const InputDecoration(
              hintText: 'Re-enter 4-digit PIN',
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7ECFF),
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
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, _) => const Text(
                    'EmoShield',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),

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
                    const Text(
                      'Register Your Child',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _kidCard(
                      title: 'Child 1',
                      nameController: kid1Name,
                      dobController: kid1Dob,
                      pinController: kid1Pin,
                      confirmPinController: kid1ConfirmPin,
                      genderValue: kid1Gender,
                      onGenderChanged: (v) => setState(() => kid1Gender = v ?? 'Male'),
                    ),

                    if (kidsCount == 2)
                      _kidCard(
                        title: 'Child 2',
                        nameController: kid2Name,
                        dobController: kid2Dob,
                        pinController: kid2Pin,
                        confirmPinController: kid2ConfirmPin,
                        genderValue: kid2Gender,
                        onGenderChanged: (v) => setState(() => kid2Gender = v ?? 'Male'),
                      ),

                    if (kidsCount == 1)
                      TextButton(
                        onPressed: () => setState(() => kidsCount = 2),
                        child: const Text(
                          '+ Add Another Child',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
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
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F86D6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: _isSaving ? null : _saveChildren,
                        child: Text(
                          _isSaving ? 'Saving...' : 'Finish Registration',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
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