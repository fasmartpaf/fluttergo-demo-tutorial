import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_motion.dart';
import 'app_reveal.dart';

/// A small label that pops in at a slight tilt and then bobs gently — the
/// "ingredient tags" / "feature tags" floating around a hero object in
/// onboarding scenes and AI results.
class AppFloatingTag extends StatefulWidget {
  const AppFloatingTag({
    super.key,
    required this.label,
    this.index = 0,
    this.delay = Duration.zero,
    this.tilt = -0.08,
    this.dot,
    this.background,
    this.foreground,
  });

  final String label;
  final int index;
  final Duration delay;

  /// Rotation in radians (small: -0.12…0.12).
  final double tilt;

  /// Optional leading status dot colour.
  final Color? dot;
  final Color? background;
  final Color? foreground;

  @override
  State<AppFloatingTag> createState() => _AppFloatingTagState();
}

class _AppFloatingTagState extends State<AppFloatingTag> with SingleTickerProviderStateMixin {
  late final AnimationController _bob =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!AppMotion.reduced(context) && !_bob.isAnimating) _bob.repeat();
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final phase = widget.index * 0.9;
    return AppReveal.pop(
      index: widget.index,
      delay: widget.delay,
      child: AnimatedBuilder(
        animation: _bob,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 2.5 * math.sin(_bob.value * 2 * math.pi + phase)),
          child: child,
        ),
        child: Transform.rotate(
          angle: widget.tilt,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: widget.background ?? scheme.surface,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.dot != null) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: widget.dot, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  widget.label,
                  style: text.labelSmall?.copyWith(
                    color: widget.foreground ?? scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Camera / AI scan frame: dashed rounded rectangle with corner brackets and a
/// light band sweeping top to bottom while [scanning]. Put it over a photo,
/// then pop [AppFloatingTag]s and slide a result sheet in when done.
class AppScanFrame extends StatefulWidget {
  const AppScanFrame({
    super.key,
    this.size = const Size(200, 150),
    this.scanning = true,
    this.color = const Color(0xFFFFFFFF),
  });

  final Size size;
  final bool scanning;
  final Color color;

  @override
  State<AppScanFrame> createState() => _AppScanFrameState();
}

class _AppScanFrameState extends State<AppScanFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _sweep =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  void _sync() {
    if (widget.scanning && !AppMotion.reduced(context)) {
      if (!_sweep.isAnimating) _sweep.repeat();
    } else {
      _sweep.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(AppScanFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: widget.size,
      child: AnimatedBuilder(
        animation: _sweep,
        builder: (context, _) => CustomPaint(
          painter: _ScanPainter(
            t: _sweep.value,
            color: widget.color,
            scanning: widget.scanning,
          ),
        ),
      ),
    );
  }
}

class _ScanPainter extends CustomPainter {
  _ScanPainter({required this.t, required this.color, required this.scanning});

  final double t;
  final Color color;
  final bool scanning;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(18));
    canvas.drawRRect(rrect, Paint()..color = color.withAlpha(30));
    final dash = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 7, metric.length)), dash);
        d += 12;
      }
    }
    final corner = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    const c = 22.0;
    final r = rect.deflate(1);
    for (final p in [
      [r.topLeft, const Offset(c, 0), const Offset(0, c)],
      [r.topRight, const Offset(-c, 0), const Offset(0, c)],
      [r.bottomLeft, const Offset(c, 0), const Offset(0, -c)],
      [r.bottomRight, const Offset(-c, 0), const Offset(0, -c)],
    ]) {
      canvas.drawLine(p[0], p[0] + p[1], corner);
      canvas.drawLine(p[0], p[0] + p[2], corner);
    }
    if (scanning) {
      final y = r.top + r.height * t;
      final band = Rect.fromLTRB(r.left + 6, y - 18, r.right - 6, y + 2);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withAlpha(0), color.withAlpha(110)],
          ).createShader(band),
      );
    }
  }

  @override
  bool shouldRepaint(_ScanPainter old) => old.t != t || old.scanning != scanning || old.color != color;
}

/// A quiz / preference choice for personalisation onboarding: tap fills it
/// (inverted colours, check pops in), unselect empties it.
class AppChoiceTile extends StatelessWidget {
  const AppChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final ink = scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.md,
          curve: AppMotion.standard,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: selected ? ink : scheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? ink : scheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Text(
                label,
                style: text.titleSmall?.copyWith(color: selected ? scheme.surface : ink),
              ),
              AnimatedSwitcher(
                duration: AppMotion.sm,
                transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                child: selected
                    ? Padding(
                        key: const ValueKey('on'),
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Icons.check_rounded, size: 18, color: scheme.surface),
                      )
                    : const SizedBox(key: ValueKey('off')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin progress line with an "n/total" label for quiz-style onboarding.
class AppStepProgress extends StatelessWidget {
  const AppStepProgress({super.key, required this.value, required this.total, this.color});

  final int value;
  final int total;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.onSurface;
    final f = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$value/$total', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: c.withAlpha(30)),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: f),
                  duration: AppMotion.resolve(context, AppMotion.lg),
                  curve: AppMotion.standard,
                  builder: (context, v, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: v,
                    child: ColoredBox(color: c),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
