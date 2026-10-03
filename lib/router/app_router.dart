import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/add_habit/add_habit_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../motion/app_motion.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        pageBuilder: (context, state) => AppMotion.page(
          state: state,
          motion: PageMotion.fade,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => AppMotion.page(
          state: state,
          motion: PageMotion.fadeThrough,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => AppMotion.page(
          state: state,
          motion: PageMotion.fadeThrough,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/add',
        name: 'add_habit',
        pageBuilder: (context, state) => AppMotion.page(
          state: state,
          motion: PageMotion.slideUp,
          fullscreenDialog: true,
          child: const AddHabitScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => AppMotion.page(
          state: state,
          motion: PageMotion.sharedAxisX,
          child: const SettingsScreen(),
        ),
      ),
    ],
  );
});
