import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_motion.dart';
import 'app_pressable.dart';

/// Round "next" button whose outer ring fills as the user moves through the
/// steps. Used by the `ringCounter` chrome and the editorial shell.
class AppRingArrowButton extends StatelessWidget {
  const AppRingArrowButton({
    super.key,
    required this.progress,
    required this.onTap,
    this.color,
    this.iconColor,
    this.size = 64,
    this.done = false,
    this.semanticLabel = 'Next',
  });

  /// 0..1 — how much of the ring is drawn.
  final double progress;
  final VoidCallback? onTap;
  final Color? color;
  final Color? iconColor;
  final double size;

  /// Shows a check instead of the arrow (last step).
  final bool done;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    final fg = iconColor ?? scheme.onPrimary;
    return AppPressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: progress.clamp(0.0, 1.0)),
          duration: AppMotion.resolve(context, AppMotion.lg, essential: true),
          curve: AppMotion.enter,
          builder: (context, v, child) => CustomPaint(
            painter: _RingPainter(value: v, color: c),
            child: child,
          ),
          child: Center(
            child: Container(
              width: size - 16,
              height: size - 16,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              child: AnimatedSwitcher(
                duration: AppMotion.sm,
                transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                child: Icon(
                  done ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  key: ValueKey(done),
                  color: fg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.5;
    final r = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      r,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = color.withAlpha(40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      r,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color;
}

/// "02 / 04" step counter; the current number rolls up when it changes.
class AppStepCounter extends StatelessWidget {
  const AppStepCounter({
    super.key,
    required this.index,
    required this.total,
    this.color,
    this.mutedColor,
    this.style,
  });

  /// Zero-based current step.
  final int index;
  final int total;
  final Color? color;
  final Color? mutedColor;
  final TextStyle? style;

  static String _two(int n) => n < 10 ? '0$n' : '$n';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = (style ?? Theme.of(context).textTheme.titleMedium ?? const TextStyle())
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()], fontWeight: FontWeight.w700);
    return Semantics(
      label: 'Step ${index + 1} of $total',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRect(
              child: AnimatedSwitcher(
                duration: AppMotion.resolve(context, AppMotion.md),
                transitionBuilder: (child, a) => SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                      .animate(CurvedAnimation(parent: a, curve: AppMotion.enter)),
                  child: child,
                ),
                child: Text(
                  _two(index + 1),
                  key: ValueKey(index),
                  style: base.copyWith(color: color ?? scheme.onSurface),
                ),
              ),
            ),
            Text(
              ' / ${_two(total)}',
              style: base.copyWith(color: mutedColor ?? scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Big headline whose words rise out of a mask one after another — the
/// editorial onboarding signature. Words matching [highlight] are painted in
/// [highlightColor] (one highlighted word per headline is the rule).
class AppMaskedHeadline extends StatefulWidget {
  const AppMaskedHeadline({
    super.key,
    required this.text,
    this.style,
    this.highlight,
    this.highlightColor,
    this.delay = Duration.zero,
  });

  final String text;
  final TextStyle? style;
  final String? highlight;
  final Color? highlightColor;
  final Duration delay;

  @override
  State<AppMaskedHeadline> createState() => _AppMaskedHeadlineState();
}

class _AppMaskedHeadlineState extends State<AppMaskedHeadline> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Timer? _wait;
  bool _started = false;

  List<String> get _words => widget.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    _c.duration = AppMotion.xl + Duration(milliseconds: 70 * _words.length);
    _wait = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _wait?.cancel();
    _c.dispose();
    super.dispose();
  }

  static String _bare(String w) => w.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = (widget.style ?? Theme.of(context).textTheme.displaySmall ?? const TextStyle())
        .copyWith(height: 1.04);
    final words = _words;
    final n = words.length;
    final hi = widget.highlight == null ? null : _bare(widget.highlight!);
    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: Wrap(
          spacing: (style.fontSize ?? 34) * 0.26,
          children: [
            for (var i = 0; i < n; i++)
              AnimatedBuilder(
                animation: _c,
                builder: (context, child) {
                  final start = n <= 1 ? 0.0 : (i / n) * 0.5;
                  final v = Interval(start, start + 0.5, curve: AppMotion.enter).transform(_c.value);
                  return ClipRect(
                    child: FractionalTranslation(translation: Offset(0, 1 - v), child: child),
                  );
                },
                child: Text(
                  words[i],
                  style: hi != null && _bare(words[i]) == hi
                      ? style.copyWith(color: widget.highlightColor ?? scheme.primary)
                      : style,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Three dots that bounce while the assistant is "typing".
class AppTypingDots extends StatefulWidget {
  const AppTypingDots({super.key, this.color});

  final Color? color;

  @override
  State<AppTypingDots> createState() => _AppTypingDotsState();
}

class _AppTypingDotsState extends State<AppTypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _c.stop();
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
    final c = widget.color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      label: 'Typing',
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Transform.translate(
                offset: Offset(0, -3 * math.max(0, math.sin((_c.value - i * 0.15) * math.pi * 2))),
                child: Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
