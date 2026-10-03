import 'package:flutter/material.dart';

import 'app_motion.dart';
import 'app_reveal.dart';

/// One day in an [AppCalendarStrip].
class AppCalendarDay {
  const AppCalendarDay({required this.weekday, required this.day, this.dots = 0});

  /// Short weekday label, e.g. 'Tue'.
  final String weekday;
  final int day;

  /// Small markers under the date (bookings, care tasks, workouts…), max 3.
  final int dots;
}

/// A week strip of day chips: chips rise in staggered, the selected day fills
/// with the accent and lifts, markers sit under each date. Tapping a chip
/// calls [onSelect]. Use in booking, planning, care and habit scenes.
class AppCalendarStrip extends StatelessWidget {
  const AppCalendarStrip({
    super.key,
    required this.days,
    required this.selected,
    this.onSelect,
    this.accent,
    this.dayKeys,
  });

  final List<AppCalendarDay> days;
  final int selected;
  final ValueChanged<int>? onSelect;
  final Color? accent;

  /// Optional keys per chip, e.g. as [AppTapStep] targets.
  final List<GlobalKey>? dayKeys;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = accent ?? scheme.primary;
    return Row(
      children: [
        for (var i = 0; i < days.length; i++)
          Expanded(
            child: AppReveal(
              index: i,
              child: GestureDetector(
                key: dayKeys != null && i < dayKeys!.length ? dayKeys![i] : null,
                onTap: onSelect == null ? null : () => onSelect!(i),
                child: AnimatedContainer(
                  duration: AppMotion.md,
                  curve: AppMotion.standard,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  transform: Matrix4.translationValues(0, i == selected ? -4 : 0, 0),
                  decoration: BoxDecoration(
                    color: i == selected ? color : scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: i == selected ? color : scheme.outlineVariant),
                    boxShadow: i == selected
                        ? [BoxShadow(color: color.withAlpha(70), blurRadius: 14, offset: const Offset(0, 6))]
                        : const [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        days[i].weekday,
                        style: text.labelSmall?.copyWith(
                          color: i == selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${days[i].day}',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: i == selected ? scheme.onPrimary : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var d = 0; d < days[i].dots.clamp(0, 3); d++)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == selected ? scheme.onPrimary : color,
                              ),
                            ),
                          if (days[i].dots == 0) const SizedBox(height: 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
