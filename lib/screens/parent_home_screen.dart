import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../app/app_router.dart';

class ParentHomeScreen extends StatelessWidget {
  final String parentName;
  final List<String> childNames;
  final List<RecentEmotion> recentEmotions;

  const ParentHomeScreen({
    super.key,
    required this.parentName,
    required this.childNames,
    required this.recentEmotions,
  });

  static const _profileIcon = 'assets/images/parents homepage_profile icon.svg';
  static const _kidIcon = 'assets/images/parents homepage_kid icon.svg';

  static const _happyIcon = 'assets/images/parents homepage_happy icon.svg';
  static const _neutralIcon = 'assets/images/parents homepage_neutral icon.svg';

  static const _reportIcon = 'assets/images/parents homepage_report icon.svg';
  static const _progressIcon = 'assets/images/parents homepage_progress icon.svg';
  static const _userIcon = 'assets/images/parents homepage_user icon.svg';

  List<RecentEmotion> _buildDisplayEmotions() {
    if (recentEmotions.isNotEmpty) return recentEmotions;

    if (childNames.isEmpty) {
      return const [
        RecentEmotion(
          childName: 'Child',
          emotionLabel: 'No Data',
          iconAsset: _neutralIcon,
          bg: Color(0xFFD7F1B5),
        ),
      ];
    }

    if (childNames.length == 1) {
      return [
        RecentEmotion(
          childName: childNames[0],
          emotionLabel: 'Happy',
          iconAsset: _happyIcon,
          bg: Color(0xFFF6C1C9),
        ),
      ];
    }

    return [
      RecentEmotion(
        childName: childNames[0],
        emotionLabel: 'Happy',
        iconAsset: _happyIcon,
        bg: const Color(0xFFF6C1C9),
      ),
      RecentEmotion(
        childName: childNames[1],
        emotionLabel: 'Neutral',
        iconAsset: _neutralIcon,
        bg: const Color(0xFFD7F1B5),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final displayEmotions = _buildDisplayEmotions();

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
                    'Welcome, $parentName',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.parentProfileDashboard,
                    ),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF2F86D6),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          _profileIcon,
                          width: 22,
                          height: 22,
                          placeholderBuilder: (_) => const Icon(
                            Icons.person,
                            color: Color(0xFF2F86D6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: Container(
                      height: 170,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2FE6),
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
                                  'Hello, $parentName',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Let’s look into the kids'\nemotion insights and\nplay activities.",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SvgPicture.asset(
                            _kidIcon,
                            width: 86,
                            height: 86,
                            placeholderBuilder: (_) =>
                                const SizedBox(width: 86, height: 86),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Emotions',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        _EmotionMiniCard(emotion: displayEmotions[0]),
                        if (displayEmotions.length > 1) ...[
                          const SizedBox(height: 10),
                          _EmotionMiniCard(emotion: displayEmotions[1]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _ParentActionCard(
                color: const Color(0xFF2AA8B9),
                iconSvg: _reportIcon,
                title: 'Emotional Report',
                subtitle:
                    'View clear emotion insights\nto understand how your child\nfelt during gameplay.',
                buttonText: 'View Now',
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.emotionalReport),
              ),
              const SizedBox(height: 12),

              _ParentActionCard(
                color: const Color(0xFF7B2CCB),
                iconSvg: _progressIcon,
                title: "Kids' Progress",
                subtitle:
                    "Monitor your child's learning\nprogress, gameplay\nachievements, and milestones.",
                buttonText: 'Manage Profile',
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.progressReport),
              ),
              const SizedBox(height: 12),

              _ParentActionCard(
                color: const Color(0xFFF19A3E),
                iconSvg: _userIcon,
                title: 'Profile Dashboard',
                subtitle:
                    'Manage your account details,\nsettings, and the profiles\nlinked to your family.',
                buttonText: 'View Dashboard',
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRouter.parentProfileDashboard,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecentEmotion {
  final String childName;
  final String emotionLabel;
  final String iconAsset;
  final Color bg;

  const RecentEmotion({
    required this.childName,
    required this.emotionLabel,
    required this.iconAsset,
    required this.bg,
  });
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

class _EmotionMiniCard extends StatelessWidget {
  final RecentEmotion emotion;

  const _EmotionMiniCard({required this.emotion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: emotion.bg,
        borderRadius: BorderRadius.circular(16),
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
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              emotion.childName,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 8),
          SvgPicture.asset(
            emotion.iconAsset,
            width: 58,
            height: 58,
            placeholderBuilder: (_) =>
                const SizedBox(width: 58, height: 58),
          ),
          const SizedBox(height: 6),
          Text(
            emotion.emotionLabel,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ParentActionCard extends StatelessWidget {
  final Color color;
  final String iconSvg;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const _ParentActionCard({
    required this.color,
    required this.iconSvg,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: color,
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
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(217),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: SvgPicture.asset(
                iconSvg,
                width: 56,
                height: 56,
                placeholderBuilder: (_) =>
                    const SizedBox(width: 56, height: 56),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.2,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 38,
                  width: 150,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
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