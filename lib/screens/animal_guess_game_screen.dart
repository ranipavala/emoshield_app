import 'package:flutter/material.dart';

class AnimalGuessGameScreen extends StatelessWidget {
  const AnimalGuessGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const answer = 'FOX';
    const letters = ['X', 'A', 'F', 'J', 'L', 'O', 'I'];

    return Scaffold(
      backgroundColor: const Color(0xFFD7ECFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/emoshield_logo.png',
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, _) => const Text(
                      'EmoShield',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const Spacer(),
                  const _TopAvatar(),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Which animal is this?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 28),
              const _FoxFace(),
              const SizedBox(height: 34),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: answer.split('').map((letter) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Text(
                          letter,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF44AA73),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 22,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9D9D9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 26),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: letters.map((letter) {
                  final isRed = ['X', 'F', 'O'].contains(letter);
                  return Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isRed ? const Color(0xFFEF4458) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 4,
                          offset: Offset(0, 3),
                          color: Color(0x22000000),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: isRed ? Colors.white : const Color(0xFFEF4458),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4C522),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    'FINISH',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Colors.white,
                    ),
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

class _TopAvatar extends StatelessWidget {
  const _TopAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD96BB5), width: 2),
      ),
      child: const ClipOval(
        child: ColoredBox(
          color: Colors.white,
          child: Icon(Icons.person, color: Colors.red),
        ),
      ),
    );
  }
}

class _FoxFace extends StatelessWidget {
  const _FoxFace();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.pets,
          size: 96,
          color: Color(0xFFF39B43),
        ),
        const SizedBox(height: 6),
        Container(
          width: 120,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7E9),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }
}