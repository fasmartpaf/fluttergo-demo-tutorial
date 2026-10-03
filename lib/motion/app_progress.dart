import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'app_draw_check.dart';
import 'app_motion.dart';

/// Ring that fills to [value] (0 → 1) and animates every change.
/// Daily goals, minutes, storage, completion.
class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    super.key,
    required this.value,
    this.size = 56,
    this.stroke = 6,
    this.color = const Color(0xFF2E9E6B),
    this.track = const Color(0xFFE6EBE8),
    this.child,
    this.duration,
  });

  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Color track;
  final Widget? child;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      value: '${(value * 100).round()}%',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: value.clamp(0.0, 1.0)),
        duration: AppMotion.resolve(context, duration ?? const Duration(milliseconds: 900),
            essential: true),
        curve: AppMotion.enter,
        builder: (context, v, child) => CustomPaint(
          painter: _RingPainter(v, stroke, color, track),
          child: SizedBox.square(dimension: size, child: Center(child: child)),
        ),
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.stroke, this.color, this.track);
  final double v;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, p..color = track);
    if (v > 0) canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * v, false, p..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.color != color || o.track != track;
}

/// Row of segments that fill one by one ("4 of 5 habits", "3 of 8 glasses").
/// Newly filled segments grow in from the left, 60 ms apart.
class AppSegmentBar extends StatelessWidget {
  const AppSegmentBar({
    super.key,
    required this.filled,
    required this.total,
    this.height = 8,
    this.gap = 4,
    this.color = const Color(0xFFF2C14E),
    this.track = const Color(0x40FFFFFF),
  });

  final int filled;
  final int total;
  final double height;
  final double gap;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);
    return Semantics(
      value: '$filled of $total',
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Expanded(
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: track,
                  borderRadius: BorderRadius.circular(height),
                ),
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: i < filled ? 1 : 0),
                  duration: reduce ? Duration.zero : AppMotion.lg + AppMotion.stagger * 1.5 * i,
                  curve: AppMotion.enter,
                  builder: (context, v, _) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(height),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A completion circle: empty ring → filled with a drawn check.
/// Habit rows, to-do items, onboarding checklists, streak days.
class AppCheckCircle extends StatelessWidget {
  const AppCheckCircle({
    super.key,
    required this.checked,
    this.size = 26,
    this.color = const Color(0xFF2E9E6B),
    this.border = const Color(0xFFC9D2CD),
  });

  final bool checked;
  final double size;
  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      child: AnimatedContainer(
        duration: AppMotion.resolve(context, AppMotion.md, essential: true),
        curve: AppMotion.curve(context, AppMotion.pop),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: checked ? color : const Color(0x00000000),
          border: Border.all(color: checked ? color : border, width: 2),
        ),
        child: AnimatedSwitcher(
          duration: AppMotion.resolve(context, AppMotion.sm),
          transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
          child: checked
              ? Center(
                  key: const ValueKey(true),
                  child: AppDrawCheck(size: size * 0.75, strokeWidth: 2.6, semanticLabel: 'Done'),
                )
              : const SizedBox.shrink(key: ValueKey(false)),
        ),
      ),
    );
  }
}
