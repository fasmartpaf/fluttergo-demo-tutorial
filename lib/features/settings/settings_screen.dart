import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../assets/app_assets.dart';
import '../../motion/motion.dart';
import '../../providers/habits_provider.dart';
import '../../theme/app_chrome.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const colors = AppColors.light;
    final text = Theme.of(context).textTheme;
    final reduceMotion = ref.watch(reduceMotionProvider);
    final habitCount = ref.watch(habitsProvider).length;
    final bestStreak = ref.watch(bestStreakProvider);

    return ChromeScope(
      top: colors.background,
      bottom: colors.background,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('Settings'),
          leading: AppPressable(
            onTap: () => context.pop(),
            semanticLabel: 'Back',
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.arrow_back_rounded),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            AppReveal(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.line),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        AppAssets.homeHero,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: colors.primary,
                          alignment: Alignment.center,
                          child: Text(
                            'A',
                            style: text.headlineSmall?.copyWith(
                              color: colors.surface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Alex Rivera', style: text.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            'Building calmer mornings',
                            style: text.bodyMedium?.copyWith(
                              color: colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppReveal(
              index: 1,
              child: Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Habits',
                      value: habitCount,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: 'Best streak',
                      value: bestStreak,
                      suffix: 'd',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppReveal(
              index: 2,
              child: Text('Preferences', style: text.titleMedium),
            ),
            const SizedBox(height: 10),
            AppReveal(
              index: 3,
              child: _SettingsCard(
                children: [
                  _SettingsRow(
                    icon: Icons.motion_photos_off_rounded,
                    title: 'Reduce motion',
                    subtitle: 'Simpler animations on this device',
                    trailing: Switch.adaptive(
                      value: reduceMotion,
                      activeTrackColor: colors.primary,
                      onChanged: (v) =>
                          ref.read(reduceMotionProvider.notifier).setEnabled(v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppReveal(
              index: 4,
              child: Text('About', style: text.titleMedium),
            ),
            const SizedBox(height: 10),
            AppReveal(
              index: 5,
              child: _SettingsCard(
                children: [
                  _SettingsRow(
                    icon: Icons.info_outline_rounded,
                    title: 'Habits Demo',
                    subtitle: 'Daily habits · local demo data · v1.0.0 (1)',
                  ),
                  Divider(height: 1, color: colors.line),
                  _SettingsRow(
                    icon: Icons.cloud_off_rounded,
                    title: 'No backend',
                    subtitle: 'Habits stay in this session until you add sync',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.suffix = '',
  });

  final String label;
  final int value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.light;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.bodySmall),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppCountUp(
                value: value,
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (suffix.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2, left: 2),
                  child: Text(suffix, style: text.titleMedium),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.light;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.light;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
