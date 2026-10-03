import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app_motion.dart';

/// Horizontal error shake (2.5 cycles, 6 dp). Call
/// `shakeKey.currentState?.shake()`. Always pair with an error message:
/// under reduced motion it does nothing.
class AppShake extends StatefulWidget {
  const AppShake({super.key, required this.child});
  final Widget child;

  @override
  State<AppShake> createState() => AppShakeState();
}

class AppShakeState extends State<AppShake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: AppMotion.md);

  void shake() {
    if (AppMotion.reduced(context)) return;
    HapticFeedback.lightImpact();
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final v = _c.value;
        final dx = 6 * (1 - v) * math.sin(v * 5 * math.pi);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

/// Expanding ring behind a live element (your location, a recording dot,
/// "provider online"). It means "this is live" — don't use it as decoration.
/// Static under reduced motion.
class AppPulseHalo extends StatefulWidget {
  const AppPulseHalo({
    super.key,
    required this.child,
    this.color = const Color(0xFF1A73E8),
    this.size = 70,
    this.period = const Duration(milliseconds: 2200),
  });

  final Widget child;
  final Color color;
  final double size;
  final Duration period;

  @override
  State<AppPulseHalo> createState() => _AppPulseHaloState();
}

class _AppPulseHaloState extends State<AppPulseHalo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _c.stop();
      _c.value = 0.4;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = AppMotion.standard.transform(_c.value);
                return Opacity(
                  opacity: (1 - t) * 0.9,
                  child: Container(
                    width: widget.size * (0.25 + 0.75 * t),
                    height: widget.size * (0.25 + 0.75 * t),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withAlpha(46),
                    ),
                  ),
                );
              },
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
