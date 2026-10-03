import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit.dart';
import '../motion/app_motion.dart';

/// Seed habits — named rituals with real streaks (local mock, no backend).
final List<Habit> _seedHabits = [
  const Habit(
    id: 'stretch',
    name: 'Morning stretch',
    icon: Icons.self_improvement_rounded,
    streak: 12,
    doneToday: false,
    accent: Color(0xFF2A9B6A),
  ),
  const Habit(
    id: 'water',
    name: 'Drink 8 glasses',
    icon: Icons.local_drink_rounded,
    streak: 7,
    doneToday: true,
    accent: Color(0xFF3B8EA5),
  ),
  const Habit(
    id: 'read',
    name: 'Read 20 minutes',
    icon: Icons.menu_book_rounded,
    streak: 5,
    doneToday: false,
    accent: Color(0xFFC9852A),
  ),
  const Habit(
    id: 'walk',
    name: 'Walk after lunch',
    icon: Icons.directions_walk_rounded,
    streak: 3,
    doneToday: false,
    accent: Color(0xFF5B7C99),
  ),
  const Habit(
    id: 'journal',
    name: 'Journal 3 lines',
    icon: Icons.edit_note_rounded,
    streak: 9,
    doneToday: false,
    accent: Color(0xFF7A6BB0),
  ),
];

class HabitsNotifier extends StateNotifier<List<Habit>> {
  HabitsNotifier() : super(List<Habit>.from(_seedHabits));

  void toggle(String id) {
    state = [
      for (final habit in state)
        if (habit.id == id)
          habit.copyWith(
            doneToday: !habit.doneToday,
            streak: habit.doneToday
                ? (habit.streak > 0 ? habit.streak - 1 : 0)
                : habit.streak + 1,
          )
        else
          habit,
    ];
  }

  void add({required String name, required IconData icon}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final id = 'habit_${DateTime.now().millisecondsSinceEpoch}';
    state = [
      ...state,
      Habit(
        id: id,
        name: trimmed,
        icon: icon,
        streak: 0,
        doneToday: false,
        accent: const Color(0xFF2A9B6A),
      ),
    ];
  }

  void remove(String id) {
    state = state.where((h) => h.id != id).toList();
  }
}

final habitsProvider =
    StateNotifierProvider<HabitsNotifier, List<Habit>>((ref) {
  return HabitsNotifier();
});

final doneCountProvider = Provider<int>((ref) {
  return ref.watch(habitsProvider).where((h) => h.doneToday).length;
});

final dayProgressProvider = Provider<double>((ref) {
  final habits = ref.watch(habitsProvider);
  if (habits.isEmpty) return 0;
  final done = habits.where((h) => h.doneToday).length;
  return done / habits.length;
});

final bestStreakProvider = Provider<int>((ref) {
  final habits = ref.watch(habitsProvider);
  if (habits.isEmpty) return 0;
  return habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
});

/// Session flag — welcome shown once per app launch.
class OnboardingSeenNotifier extends StateNotifier<bool> {
  OnboardingSeenNotifier() : super(false);

  void complete() => state = true;
}

final onboardingSeenProvider =
    StateNotifierProvider<OnboardingSeenNotifier, bool>((ref) {
  return OnboardingSeenNotifier();
});

class ReduceMotionNotifier extends StateNotifier<bool> {
  ReduceMotionNotifier() : super(AppMotion.appReduceMotion);

  void setEnabled(bool value) {
    AppMotion.appReduceMotion = value;
    state = value;
  }
}

final reduceMotionProvider =
    StateNotifierProvider<ReduceMotionNotifier, bool>((ref) {
  return ReduceMotionNotifier();
});
