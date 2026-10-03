import 'dart:async';

import 'package:flutter/material.dart';

import 'app_motion.dart';

/// Branded launch moment: a glow blooms, the mark pops in with a small turn,
/// the name rises, the tagline fades in, then [onDone] fires (~2 s total).
///
/// Keep it short: it is a brand beat, not a loading screen. Do real loading
/// in parallel and call `context.go(...)` from [onDone]. Under reduced motion
/// it shows the final frame and continues after 600 ms.
///
/// ```dart
/// AppSplash(
///   mark: AppLogoMark(name: 'Sprout', asset: AppAssets.logo),
///   title: 'Sprout',
///   tagline: 'Small habits, every day',
///   background: AppColors.light.ink,
///   glow: AppColors.light.primary,
///   onDone: () => context.go(seenOnboarding ? '/' : '/onboarding'),
/// )
/// ```
class AppSplash extends StatefulWidget {
  const AppSplash({
    super.key,
    required this.mark,
    required this.title,
    required this.onDone,
    this.tagline,
    this.background = const Color(0xFF0E1116),
    this.glow = const Color(0xFF2E9E6B),
    this.foreground = const Color(0xFFFFFFFF),
    this.hold = const Duration(milliseconds: 650),
    this.titleStyle,
  });

  final Widget mark;
  final String title;
  final String? tagline;
  final VoidCallback onDone;
  final Color background;
  final Color glow;
  final Color foreground;

  /// Pause on the finished frame before [onDone].
  final Duration hold;
  final TextStyle? titleStyle;

  @override
  State<AppSplash> createState() => _AppSplashState();
}

class _AppSplashState extends State<AppSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  Timer? _done;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _c.value = 1;
      _done = Timer(const Duration(milliseconds: 600), _finish);
      return;
    }
    _c.forward().whenComplete(() {
      if (mounted) _done = Timer(widget.hold, _finish);
    });
  }

  void _finish() {
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _done?.cancel();
    _c.dispose();
    super.dispose();
  }

  double _seg(double a, double b, Curve curve) =>
      curve.transform(Interval(a, b).transform(_c.value));

  @override
  Widget build(BuildContext context) {
    final base = widget.titleStyle ??
        Theme.of(context).textTheme.headlineMedium ??
        const TextStyle(fontSize: 28);
    return Semantics(
      label: widget.title,
      // Material so the name and tagline get a real text style even when the
      // splash route has no Scaffold.
      child: Material(
        color: widget.background,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final glow = _seg(0, 0.7, AppMotion.enter);
            final mark = _seg(0.05, 0.55, AppMotion.pop);
            final title = _seg(0.35, 0.8, AppMotion.enter);
            final tag = _seg(0.55, 1, AppMotion.standard);
            return Stack(
              alignment: Alignment.center,
              children: [
                // Soft bloom behind the mark.
                Opacity(
                  opacity: (glow * 0.9).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.6 + 0.6 * glow,
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [widget.glow.withAlpha(110), widget.glow.withAlpha(0)],
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: const Interval(0, 0.4).transform(mark.clamp(0.0, 1.0)),
                      child: Transform.rotate(
                        angle: -0.12 * (1 - mark),
                        child: Transform.scale(scale: 0.55 + 0.45 * mark, child: widget.mark),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Opacity(
                      opacity: title.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - title)),
                        child: Text(
                          widget.title,
                          style: base.copyWith(
                            color: widget.foreground,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    if (widget.tagline != null) ...[
                      const SizedBox(height: 6),
                      Opacity(
                        opacity: tag.clamp(0.0, 1.0),
                        child: Text(
                          widget.tagline!,
                          style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
                              .copyWith(color: widget.foreground.withAlpha(190)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The app's logo for [AppSplash] and onboarding: shows [asset] when it
/// exists, otherwise a rounded monogram of [name] in [color], so a missing
/// logo file never leaves an empty splash.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({
    super.key,
    required this.name,
    this.asset,
    this.size = 88,
    this.color,
    this.foreground = const Color(0xFFFFFFFF),
  });

  final String name;
  final String? asset;
  final double size;
  final Color? color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter = trimmed.isEmpty ? '•' : trimmed.substring(0, 1).toUpperCase();
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: foreground,
          fontSize: size * 0.5,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
    final path = asset;
    if (path == null || path.isEmpty) return fallback;
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => fallback,
    );
  }
}

