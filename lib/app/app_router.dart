import 'package:flutter/material.dart';

import '../screens/animal_guess_game_screen.dart';
import '../screens/child_home_screen.dart';
import '../screens/child_profile_dashboard_screen.dart';
import '../screens/emotional_report_screen.dart';
import '../screens/games_screen.dart';
import '../screens/kids_registration_screen.dart';
import '../screens/level_result_screen.dart';
import '../screens/login_screen.dart';
import '../screens/parent_home_screen.dart';
import '../screens/parent_profile_dashboard_screen.dart';
import '../screens/pattern_recognition_game_screen.dart';
import '../screens/profile_select_screen.dart';
import '../screens/progress_report_screen.dart';
import '../screens/shape_match_game_screen.dart';
import '../screens/signup_parent_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/user_profile_screen.dart';

class AppRouter {
  static const splash = '/';
  static const login = '/login';
  static const parentSignup = '/parent-signup';
  static const kidsRegistration = '/kids-registration';
  static const profileSelect = '/profile';
  static const parentHome = '/parent';
  static const childHome = '/child';
  static const games = '/games';
  static const shapeMatchGame = '/shape-match-game';
  static const animalGuessGame = '/animal-guess-game';
  static const patternRecognitionGame = '/pattern-recognition-game';
  static const levelResult = '/level-result';
  static const emotionalReport = '/report';
  static const progressReport = '/progress';
  static const userProfile = '/user';
  static const parentProfileDashboard = '/parent-profile-dashboard';
  static const childProfileDashboard = '/child-profile-dashboard';

  static final routes = <String, WidgetBuilder>{
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    parentSignup: (_) => const ParentSignUpScreen(),
    kidsRegistration: (_) => const KidsRegistrationScreen(),
    profileSelect: (_) => const ProfileSelectScreen(),

    // demo only fallback routes; actual app flow uses pushed routes with real IDs
    childHome: (_) => const ChildHomeScreen(childId: 'demo_child', childName: 'Anika'),
    games: (_) => const GamesScreen(childId: 'demo_child', childName: 'Anika'),
    shapeMatchGame: (_) =>
        const ShapeMatchGameScreen(childId: 'demo_child', childName: 'Anika'),
    animalGuessGame: (_) =>
        const AnimalGuessGameScreen(childId: 'demo_child', childName: 'Anika'),
    patternRecognitionGame: (_) =>
        const PatternRecognitionGameScreen(childId: 'demo_child', childName: 'Anika'),
    levelResult: (_) =>
        const LevelResultScreen(childId: 'demo_child', childName: 'Anika'),

    parentHome: (_) => const ParentHomeScreen(
          parentName: 'Pavala',
          childNames: ['Child 1', 'Child 2'],
          recentEmotions: [],
        ),
    emotionalReport: (_) => const EmotionalReportScreen(),
    progressReport: (_) => const ProgressReportScreen(),
    userProfile: (_) => const UserProfileScreen(),
    parentProfileDashboard: (_) => const ParentProfileDashboardScreen(),
    childProfileDashboard: (_) => const ChildProfileDashboardScreen(),
  };
}