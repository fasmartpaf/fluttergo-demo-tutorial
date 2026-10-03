import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../motion/motion.dart';
import '../../providers/habits_provider.dart';
import '../../theme/app_chrome.dart';
import '../../theme/app_colors.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const colors = AppColors.light;
    return ChromeScope(
      top: colors.ink,
      bottom: colors.ink,
      child: AppSplash(
        mark: AppLogoMark(
          name: 'Habits Demo',
          color: colors.primary,
          foreground: colors.surface,
          size: 96,
        ),
        title: 'Habits Demo',
        tagline: 'Small habits. Clear day.',
        background: colors.ink,
        glow: colors.primary,
        foreground: colors.surface,
        onDone: () {
          final seen = ref.read(onboardingSeenProvider);
          context.go(seen ? '/home' : '/onboarding');
        },
      ),
    );
  }
}
