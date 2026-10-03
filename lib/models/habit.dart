import 'package:flutter/material.dart';

/// A daily habit tracked on the Home checklist.
class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.streak,
    required this.doneToday,
    this.accent,
  });

  final String id;
  final String name;
  final IconData icon;
  final int streak;
  final bool doneToday;
  final Color? accent;

  Habit copyWith({
    String? id,
    String? name,
    IconData? icon,
    int? streak,
    bool? doneToday,
    Color? accent,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      streak: streak ?? this.streak,
      doneToday: doneToday ?? this.doneToday,
      accent: accent ?? this.accent,
    );
  }
}

/// Icons users can pick when adding a habit.
const habitIconChoices = <IconData>[
  Icons.self_improvement_rounded,
  Icons.local_drink_rounded,
  Icons.menu_book_rounded,
  Icons.directions_walk_rounded,
  Icons.edit_note_rounded,
  Icons.fitness_center_rounded,
  Icons.bedtime_rounded,
  Icons.spa_rounded,
];
