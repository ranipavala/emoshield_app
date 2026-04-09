import 'package:flutter/material.dart';

class ShapeMatchGameScreen extends StatelessWidget {
  const ShapeMatchGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  _TopAvatar(),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Match shape with\nits name.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF6A33),
                ),
              ),
              const SizedBox(height: 26),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          _SquareShape(),
                          _StarShape(),
                          _TriangleShape(),
                          _CircleShape(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          _NameBubble(
                            label: 'Triangle',
                            color: Color(0xFF8FE4E3),
                            textColor: Color(0xFF289A97),
                          ),
                          _NameBubble(
                            label: 'Circle',
                            color: Color(0xFFF5A8B5),
                            textColor: Color(0xFFC64563),
                          ),
                          _NameBubble(
                            label: 'Star',
                            color: Color(0xFFEFD7AA),
                            textColor: Color(0xFFD29B2A),
                          ),
                          _NameBubble(
                            label: 'Square',
                            color: Color(0xFFA8E6AD),
                            textColor: Color(0xFF36A54B),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
      child: ClipOval(
        child: Image.asset(
          'assets/images/parents homepage_profile icon.svg',
          errorBuilder: (_, __, _) => const Icon(Icons.person, color: Colors.red),
        ),
      ),
    );
  }
}

class _SquareShape extends StatelessWidget {
  const _SquareShape();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: const Color(0xFFA8E6AD),
    );
  }
}

class _TriangleShape extends StatelessWidget {
  const _TriangleShape();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(48, 42),
      painter: _TrianglePainter(const Color(0xFF8FE4E3)),
    );
  }
}

class _StarShape extends StatelessWidget {
  const _StarShape();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.star,
      size: 52,
      color: Color(0xFFEFD7AA),
    );
  }
}

class _CircleShape extends StatelessWidget {
  const _CircleShape();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF5A8B5),
      ),
    );
  }
}

class _NameBubble extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _NameBubble({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 98,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}