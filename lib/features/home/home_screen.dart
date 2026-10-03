import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/habit.dart';
import '../../motion/motion.dart';
import '../../providers/habits_provider.dart';
import '../../theme/app_chrome.dart';
import '../../theme/app_colors.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const colors = AppColors.light;
    final text = Theme.of(context).textTheme;
    final habits = ref.watch(habitsProvider);
    final done = ref.watch(doneCountProvider);
    final progress = ref.watch(dayProgressProvider);
    final bestStreak = ref.watch(bestStreakProvider);

    return ChromeScope(
      top: colors.background,
      bottom: colors.background,
      child: Scaffold(
        backgroundColor: colors.background,
        floatingActionButton: AppReveal.pop(
          delay: const Duration(milliseconds: 400),
          child: FloatingActionButton.extended(
            onPressed: () => context.push('/add'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add habit'),
          ),
        ),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppReveal(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: text.bodyMedium?.copyWith(
                                  color: colors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Today\'s habits',
                                style: text.headlineMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppPressable(
                        onTap: () => context.push('/settings'),
                        semanticLabel: 'Settings',
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.line),
                          ),
                          child: Icon(
                            Icons.settings_rounded,
                            color: colors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: AppReveal(
                    index: 1,
                    child: _DayProgressCard(
                      done: done,
                      total: habits.length,
                      progress: progress,
                      bestStreak: bestStreak,
                    ),
                  ),
                ),
              ),
              if (habits.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyHabits(
                    onAdd: () => context.push('/add'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList.separated(
                    itemCount: habits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      return AppReveal(
                        index: index + 2,
                        child: _HabitRow(
                          habit: habit,
                          onToggle: () =>
                              ref.read(habitsProvider.notifier).toggle(habit.id),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayProgressCard extends StatelessWidget {
  const _DayProgressCard({
    required this.done,
    required this.total,
    required this.progress,
    required this.bestStreak,
  });

  final int done;
  final int total;
  final double progress;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.light;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          AppProgressRing(
            value: progress,
            size: 88,
            stroke: 9,
            color: colors.primary,
            track: colors.line,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppCountUp(
                  value: done,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Text(
                  'of $total',
                  style: text.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress >= 1 && total > 0
                      ? 'Day complete'
                      : 'Keep going',
                  style: text.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  total == 0
                      ? 'Add your first habit to start the day ring.'
                      : '$done of $total habits done today.',
                  style: text.bodyMedium?.copyWith(color: colors.muted),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.secondary.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 18,
                        color: colors.ink,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Best streak ',
                        style: text.labelLarge?.copyWith(fontSize: 13),
                      ),
                      AppCountUp(
                        value: bestStreak,
                        style: text.labelLarge?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        ' days',
                        style: text.labelLarge?.copyWith(fontSize: 13),
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

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    required this.habit,
    required this.onToggle,
  });

  final Habit habit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.light;
    final text = Theme.of(context).textTheme;
    final accent = habit.accent ?? colors.primary;

    return AppPressable(
      onTap: onToggle,
      haptic: true,
      semanticLabel: habit.doneToday
          ? '${habit.name}, done, ${habit.streak} day streak'
          : '${habit.name}, not done, ${habit.streak} day streak',
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: habit.doneToday
                ? colors.primary.withValues(alpha: 0.35)
                : colors.line,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(habit.icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: text.titleMedium?.copyWith(
                      decoration:
                          habit.doneToday ? TextDecoration.lineThrough : null,
                      color: habit.doneToday ? colors.muted : colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 16,
                        color: colors.muted,
                      ),
                      const SizedBox(width: 4),
                      AppCountUp(
                        value: habit.streak,
                        style: text.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.muted,
                        ),
                      ),
                      Text(
                        ' day streak',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppCheckCircle(
              checked: habit.doneToday,
              color: colors.primary,
              border: colors.line,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHabits extends StatelessWidget {
  const _EmptyHabits({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.light;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppReveal.pop(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.line),
              ),
              child: Icon(
                Icons.checklist_rounded,
                size: 40,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('No habits yet', style: text.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Add one small ritual and start filling today\'s day ring.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 24),
          AppPressable(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Add a habit',
                style: text.labelLarge?.copyWith(color: colors.surface),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
