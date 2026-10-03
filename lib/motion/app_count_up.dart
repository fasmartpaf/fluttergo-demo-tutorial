import 'package:flutter/widgets.dart';

import 'app_motion.dart';

/// Number that counts to [value] (prices, totals, ETAs, step counts).
///
/// Animates from [from] on first build, then from the previous value whenever
/// [value] changes. Uses tabular figures so digits don't jitter.
/// Shows the final value immediately under reduced motion.
class AppCountUp extends StatelessWidget {
  const AppCountUp({
    super.key,
    required this.value,
    this.from = 0,
    this.duration,
    this.curve,
    this.format,
    this.style,
  });

  final num value;
  final num from;
  final Duration? duration;
  final Curve? curve;

  /// Formats the in-between value, e.g. `(v) => '\$${v.toStringAsFixed(2)}'`.
  final String Function(double value)? format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);
    final base = style ?? DefaultTextStyle.of(context).style;
    final textStyle = base.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: from.toDouble(), end: value.toDouble()),
      duration: reduce ? Duration.zero : (duration ?? const Duration(milliseconds: 900)),
      curve: curve ?? AppMotion.enter,
      builder: (context, v, _) => Text(
        format?.call(v) ?? v.round().toString(),
        style: textStyle,
      ),
    );
  }
}
