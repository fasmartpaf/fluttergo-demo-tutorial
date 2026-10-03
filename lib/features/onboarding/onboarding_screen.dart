import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../assets/app_assets.dart';
import '../../motion/motion.dart';
import '../../providers/habits_provider.dart';
import '../../theme/app_chrome.dart';
import '../../theme/app_colors.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _checkedDemo = false;
  final _stretchKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.light;
    final text = Theme.of(context).textTheme;

    return ChromeScope(
      top: colors.background,
      bottom: colors.background,
      child: AppWelcomeAuth(
        background: colors.background,
        heroFlex: 12,
        hero: _WelcomeHero(
          checked: _checkedDemo,
          stretchKey: _stretchKey,
          onCheck: () => setState(() => _checkedDemo = true),
        ),
        headline: [
          [const AppHeadlinePart('Tick habits.')],
          [
            const AppHeadlinePart(
              'Watch the day',
              tone: AppHeadlineTone.muted,
            ),
          ],
          [
            AppHeadlinePart(
              'ring fill.',
              style: text.displaySmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
        headlineStyle: text.displaySmall?.copyWith(height: 1.15),
        options: [
          AppWelcomeOption(
            label: 'Get started',
            kind: AppWelcomeOptionKind.primary,
            onTap: () {
              ref.read(onboardingSeenProvider.notifier).complete();
              context.go('/home');
            },
          ),
        ],
        footer: Text(
          'No account needed · demo data stays on this device',
          style: text.bodySmall,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({
    required this.checked,
    required this.stretchKey,
    required this.onCheck,
  });

  final bool checked;
  final GlobalKey stretchKey;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.light;
    final text = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.onboardingHero,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: colors.primary),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.ink.withValues(alpha: 0.15),
                  colors.ink.withValues(alpha: 0.72),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: AppReveal.pop(
                    child: AppProgressRing(
                      value: checked ? 0.4 : 0.2,
                      size: 64,
                      stroke: 7,
                      color: colors.secondary,
                      track: colors.surface.withValues(alpha: 0.35),
                      child: Text(
                        checked ? '2/5' : '1/5',
                        style: text.labelLarge?.copyWith(
                          color: colors.surface,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                AppTapHint(
                  steps: [
                    AppTapStep(
                      target: stretchKey,
                      at: const Duration(milliseconds: 900),
                      onTap: onCheck,
                    ),
                  ],
                  child: Column(
                    children: [
                      KeyedSubtree(
                        key: stretchKey,
                        child: _DemoHabitChip(
                          label: 'Morning stretch',
                          photo: AppAssets.habitPhotoStretch,
                          checked: checked,
                          onTap: onCheck,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _DemoHabitChip(
                        label: 'Drink 8 glasses',
                        photo: AppAssets.habitPhotoWater,
                        checked: true,
                        onTap: () {},
                      ),
                      const SizedBox(height: 10),
                      _DemoHabitChip(
                        label: 'Read 20 minutes',
                        photo: AppAssets.habitPhotoRead,
                        checked: false,
                        onTap: () {},
                      ),
                    ],
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

class _DemoHabitChip extends StatelessWidget {
  const _DemoHabitChip({
    required this.label,
    required this.photo,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final String photo;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.light;
    final text = Theme.of(context).textTheme;

    return AppPressable(
      onTap: onTap,
      haptic: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                photo,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  color: colors.line,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: text.titleMedium?.copyWith(
                  decoration: checked ? TextDecoration.lineThrough : null,
                  color: checked ? colors.muted : colors.ink,
                ),
              ),
            ),
            AppCheckCircle(
              checked: checked,
              color: colors.primary,
              border: colors.line,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
