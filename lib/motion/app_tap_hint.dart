import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_motion.dart';

/// One scripted demo tap: at [at], a fingertip moves onto [target] and
/// [onTap] runs (pick a day, tick a habit, press Confirm).
class AppTapStep {
  const AppTapStep({required this.target, required this.at, required this.onTap});

  final GlobalKey target;
  final Duration at;
  final VoidCallback onTap;
}

/// Ghost-finger demo for onboarding and empty-state walkthroughs: shows
/// people *how* the product works before they use it. The demo stops as soon
/// as the user touches anything inside [child]. Under reduced motion the
/// fingertip is hidden but the steps still run, so the screen ends in the same
/// state.
class AppTapHint extends StatefulWidget {
  const AppTapHint({super.key, required this.child, required this.steps, this.enabled = true});

  final Widget child;
  final List<AppTapStep> steps;
  final bool enabled;

  @override
  State<AppTapHint> createState() => _AppTapHintState();
}

class _AppTapHintState extends State<AppTapHint> {
  final _timers = <Timer>[];
  final _self = GlobalKey();
  Offset? _finger;
  int _tap = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !widget.enabled) return;
    _started = true;
    for (final step in widget.steps) {
      _timers.add(Timer(step.at, () => _run(step)));
    }
  }

  void _run(AppTapStep step) {
    if (!mounted) return;
    final box = step.target.currentContext?.findRenderObject() as RenderBox?;
    final me = _self.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || me == null || !box.attached) {
      step.onTap();
      return;
    }
    final center = box.localToGlobal(box.size.center(Offset.zero), ancestor: me);
    setState(() {
      _finger = AppMotion.reduced(context) ? null : center;
      _tap++;
    });
    _timers.add(Timer(const Duration(milliseconds: 260), () {
      if (mounted) step.onTap();
    }));
  }

  void _stop() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    if (_finger != null) setState(() => _finger = null);
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _self,
      clipBehavior: Clip.none,
      children: [
        Listener(onPointerDown: (_) => _stop(), child: widget.child),
        if (_finger != null)
          Positioned(
            left: _finger!.dx - 17,
            top: _finger!.dy - 17,
            child: IgnorePointer(child: _Fingertip(key: ValueKey(_tap))),
          ),
      ],
    );
  }
}

class _Fingertip extends StatelessWidget {
  const _Fingertip({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      builder: (context, t, _) {
        final press = t < .4 ? 1.0 : (t < .6 ? 1 - (t - .4) : 0.8 + (t - .6) * .5);
        final o = t < .15 ? t / .15 : (t > .75 ? (1 - t) / .25 : 1.0);
        return Opacity(
          opacity: o.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: press,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x29111418),
                border: Border.all(color: const Color(0x47111418), width: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}
