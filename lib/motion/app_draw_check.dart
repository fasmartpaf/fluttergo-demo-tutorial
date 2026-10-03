import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_motion.dart';

/// A check mark that draws itself (success, booked, paid, saved).
class AppDrawCheck extends StatefulWidget {
  const AppDrawCheck({
    super.key,
    this.size = 20,
    this.color = const Color(0xFFFFFFFF),
    this.strokeWidth = 3,
    this.delay = Duration.zero,
    this.semanticLabel = 'Done',
  });

  final double size;
  final Color color;
  final double strokeWidth;
  final Duration delay;
  final String semanticLabel;

  @override
  State<AppDrawCheck> createState() => _AppDrawCheckState();
}

class _AppDrawCheckState extends State<AppDrawCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  late final Animation<double> _progress = _c.drive(CurveTween(curve: AppMotion.standard));
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    _c.duration = AppMotion.lg;
    _timer = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _CheckPainter(
            progress: _progress,
            color: widget.color,
            strokeWidth: widget.strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress, required this.color, required this.strokeWidth})
      : super(repaint: progress);

  final Animation<double> progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.20, h * 0.53)
      ..lineTo(w * 0.40, h * 0.72)
      ..lineTo(w * 0.80, h * 0.30);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final p = progress.value;
    if (p <= 0) return;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * p), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth || old.progress != progress;
}
