import 'package:flutter/widgets.dart';

import 'app_motion.dart';

/// Shimmering placeholder in the shape of the content that is loading.
/// Prefer this over a spinner whenever the layout is known.
/// The shimmer stops under reduced motion.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.base = const Color(0xFFE9ECEF),
    this.highlight = const Color(0xFFF6F7F9),
  });

  /// A circle (avatars).
  const AppSkeleton.circle({
    super.key,
    double size = 40,
    this.base = const Color(0xFFE9ECEF),
    this.highlight = const Color(0xFFF6F7F9),
  })  : width = size,
        height = size,
        radius = size / 2;

  final double? width;
  final double height;
  final double radius;
  final Color base;
  final Color highlight;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: AppMotion.shimmer);

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
    return Semantics(
      label: 'Loading',
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                colors: [widget.base, widget.highlight, widget.base],
                stops: const [0.25, 0.5, 0.75],
                transform: _Slide(_c.value * 2 - 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Slide extends GradientTransform {
  const _Slide(this.p);
  final double p;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * p, 0, 0);
}
