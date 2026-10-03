import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_motion.dart';

/// How an element arrives on screen.
enum RevealStyle {
  /// Fade + rise 16 dp. Text, list rows, cards. The default.
  rise,

  /// Opacity only. Content swapped in place, map overlays.
  fade,

  /// Scale 0.5 → 1 with a small overshoot. Pins, badges, stars, chips that "land".
  pop,

  /// Slide up from below like an iOS sheet. Bottom cards, sheets, toasts.
  sheet,

  /// Drop from above with an overshoot. In-app notifications.
  drop,

  /// Slide in from the right. Chip rails, horizontal carousels.
  slideIn,
}

/// One-shot entrance animation.
///
/// Plays once when the widget is first built (after [delay] plus a stagger of
/// [index] × 40 ms). It never replays on rebuild; give it a new [Key] to replay.
/// Under reduced motion it renders the final state immediately.
///
/// ```dart
/// AppReveal(index: i, child: ProRow(pro))           // staggered list row
/// AppReveal.pop(delay: Duration(milliseconds: 700), child: MapPin(...))
/// AppReveal.sheet(delay: Duration(milliseconds: 1750), child: ProCard(...))
/// ```
class AppReveal extends StatefulWidget {
  const AppReveal({
    super.key,
    required this.child,
    this.style = RevealStyle.rise,
    this.index = 0,
    this.delay = Duration.zero,
    this.duration,
    this.distance,
  });

  const AppReveal.fade({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.duration,
  })  : style = RevealStyle.fade,
        distance = null;

  const AppReveal.pop({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.duration,
  })  : style = RevealStyle.pop,
        distance = null;

  const AppReveal.sheet({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.duration,
    this.distance,
  }) : style = RevealStyle.sheet;

  const AppReveal.drop({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.duration,
    this.distance,
  }) : style = RevealStyle.drop;

  const AppReveal.slideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.duration,
    this.distance,
  }) : style = RevealStyle.slideIn;

  final Widget child;
  final RevealStyle style;

  /// Position in a staggered group; adds index × [AppMotion.stagger].
  final int index;
  final Duration delay;

  /// Overrides the style's default duration.
  final Duration? duration;

  /// Travel distance in logical pixels (rise/sheet/drop/slideIn).
  final double? distance;

  @override
  State<AppReveal> createState() => _AppRevealState();
}

class _AppRevealState extends State<AppReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Timer? _timer;
  bool _started = false;

  Duration get _duration =>
      widget.duration ??
      switch (widget.style) {
        RevealStyle.rise => AppMotion.lg * AppMotion.revealDurationFactor,
        RevealStyle.fade => AppMotion.md * AppMotion.revealDurationFactor,
        RevealStyle.pop => AppMotion.xl * AppMotion.revealDurationFactor,
        RevealStyle.sheet => AppMotion.sheetDuration,
        RevealStyle.drop => AppMotion.xl * 1.2,
        RevealStyle.slideIn => AppMotion.lg,
      };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    _c.duration = _duration;
    final wait = widget.delay + AppMotion.staggerDelay(widget.index);
    if (wait == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(wait, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        switch (widget.style) {
          case RevealStyle.fade:
            return Opacity(opacity: AppMotion.standard.transform(t), child: child);
          case RevealStyle.rise:
            final v = AppMotion.revealCurve.transform(t);
            final double d = widget.distance ?? AppMotion.revealDistance;
            final s0 = AppMotion.revealScaleFrom;
            return Opacity(
              opacity: const Interval(0, 0.6).transform(t),
              child: Transform.translate(
                offset: Offset(0, d * (1 - v)),
                child: Transform.scale(scale: s0 + (1 - s0) * v, child: child),
              ),
            );
          case RevealStyle.slideIn:
            final v = AppMotion.revealCurve.transform(t);
            final double d = widget.distance ?? 26.0;
            return Opacity(
              opacity: v,
              child: Transform.translate(offset: Offset(d * (1 - v), 0), child: child),
            );
          case RevealStyle.pop:
            final o = const Interval(0, 0.35).transform(t);
            final s0 = AppMotion.popScaleFrom;
            final s = s0 + (1 - s0) * AppMotion.popCurve.transform(t);
            return Opacity(opacity: o, child: Transform.scale(scale: s, child: child));
          case RevealStyle.sheet:
            final v = AppMotion.sheet.transform(t);
            final double d = widget.distance ?? 90.0;
            return Opacity(
              opacity: const Interval(0, 0.3).transform(t),
              child: Transform.translate(offset: Offset(0, d * (1 - v)), child: child),
            );
          case RevealStyle.drop:
            final v = AppMotion.pop.transform(t);
            final double d = widget.distance ?? 90.0;
            return Opacity(
              opacity: const Interval(0, 0.3).transform(t),
              child: Transform.translate(offset: Offset(0, -d * (1 - v)), child: child),
            );
        }
      },
    );
  }
}
