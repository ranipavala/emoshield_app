import 'package:flutter/material.dart';

class GameLevelScaffold extends StatelessWidget {
  final String question;
  final Widget child;
  final VoidCallback onBackPressed;
  final VoidCallback? onFinishPressed;
  final bool finishEnabled;
  final String finishLabel;
  final String levelLabel;
  final String? helperText;

  const GameLevelScaffold({
    super.key,
    required this.question,
    required this.child,
    required this.onBackPressed,
    required this.onFinishPressed,
    this.finishEnabled = true,
    this.finishLabel = 'Finish',
    this.levelLabel = 'Level 1',
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7ECFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            children: [
              Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: onBackPressed,
                  ),
                  const Spacer(),
                  Image.asset(
                    'assets/images/emoshield_logo.png',
                    height: 30,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text(
                      'EmoShield',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const Spacer(),
                  _LevelBadge(label: levelLabel),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(24),
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
                    Text(
                      question,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2F86D6),
                      ),
                    ),
                    if (helperText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        helperText!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(child: child),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: finishEnabled
                        ? const Color(0xFFF4C522)
                        : const Color(0xFFF4C522).withOpacity(0.45),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: finishEnabled ? onFinishPressed : null,
                  child: Text(
                    finishLabel,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFF2F86D6)),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String label;

  const _LevelBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF7FB8F0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
