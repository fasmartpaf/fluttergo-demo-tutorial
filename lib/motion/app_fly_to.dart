import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_motion.dart';

/// Flies a copy of [child] (usually the product photo) from the widget at
/// [from] to the widget at [to] along an arc, shrinking as it goes, then calls
/// [onArrive] — update the count and bump the badge there (see [AppBump]).
/// "Add to bag", "save to collection", "send to playlist". Under reduced
/// motion it skips the flight and calls [onArrive] at once.
Future<void> appFlyTo(
  BuildContext context, {
  required GlobalKey from,
  required GlobalKey to,
  required Widget child,
  VoidCallback? onArrive,
  Duration? duration,
  double endSize = 26,
}) {
  final overlay = Overlay.maybeOf(context);
  final fromBox = from.currentContext?.findRenderObject();
  final toBox = to.currentContext?.findRenderObject();
  final overlayBox = overlay?.context.findRenderObject();
  if (overlay == null ||
      fromBox is! RenderBox ||
      toBox is! RenderBox ||
      overlayBox is! RenderBox ||
      !fromBox.attached ||
      !toBox.attached ||
      AppMotion.reduced(context)) {
    onArrive?.call();
    return Future<void>.value();
  }
  final start = fromBox.localToGlobal(Offset.zero, ancestor: overlayBox) & fromBox.size;
  final end = toBox.localToGlobal(toBox.size.center(Offset.zero), ancestor: overlayBox);
  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _FlyTo(
      start: start,
      end: end,
      endSize: endSize,
      duration: duration ?? AppMotion.xl,
      onDone: () {
        entry.remove();
        entry.dispose();
        onArrive?.call();
        if (!done.isCompleted) done.complete();
      },
      child: child,
    ),
  );
  overlay.insert(entry);
  return done.future;
}

class _FlyTo extends StatefulWidget {
  const _FlyTo({
    required this.start,
    required this.end,
    required this.endSize,
    required this.duration,
    required this.onDone,
    required this.child,
  });

  final Rect start;
  final Offset end;
  final double endSize;
  final Duration duration;
  final VoidCallback onDone;
  final Widget child;

  @override
  State<_FlyTo> createState() => _FlyToState();
}

class _FlyToState extends State<_FlyTo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p0 = widget.start.center;
    final p2 = widget.end;
    final p1 = Offset((p0.dx + p2.dx) / 2, math.min(p0.dy, p2.dy) - 140);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = Curves.easeInOutCubic.transform(_c.value);
          final u = 1 - t;
          final pos = p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t);
          final w = widget.start.width + (widget.endSize - widget.start.width) * t;
          final h = widget.start.height + (widget.endSize - widget.start.height) * t;
          return Stack(
            children: [
              Positioned(
                left: pos.dx - w / 2,
                top: pos.dy - h / 2,
                width: w,
                height: h,
                child: Opacity(
                  opacity: t < 0.85 ? 1 : (1 - (t - 0.85) / 0.15 * 0.6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8 + 6 * t),
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Scales [child] in a quick bump whenever [trigger] changes — the bag badge
/// when an item lands, a counter when it ticks, a tab icon on new content.
class AppBump extends StatefulWidget {
  const AppBump({super.key, required this.trigger, required this.child, this.amount = 0.28});

  final Object? trigger;
  final Widget child;
  final double amount;

  @override
  State<AppBump> createState() => _AppBumpState();
}

class _AppBumpState extends State<AppBump> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: AppMotion.md);

  @override
  void didUpdateWidget(AppBump old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !AppMotion.reduced(context)) {
      _c.forward(from: 0);
    }
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
      builder: (context, child) => Transform.scale(
        scale: 1 + widget.amount * math.sin(_c.value * math.pi),
        child: child,
      ),
      child: widget.child,
    );
  }
}
