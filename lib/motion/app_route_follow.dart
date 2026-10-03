import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/widgets.dart';

import 'app_motion.dart';

/// Draws a route and places a marker along it at [progress] (0 → 1).
///
/// The driven part turns [doneColor]; the marker turns to face the road.
/// Drive [progress] from live location in the real app, or use
/// [AppRouteTrip] for a timed demo. [path] is in this widget's local pixels.
class AppRouteFollow extends StatelessWidget {
  const AppRouteFollow({
    super.key,
    required this.path,
    required this.progress,
    required this.marker,
    this.markerSize = const Size(30, 18),
    this.reveal = 1,
    this.color = const Color(0xFF1A73E8),
    this.doneColor = const Color(0xFFA8B4C4),
    this.width = 6,
    this.rotateMarker = true,
  });

  final Path path;
  final double progress;

  /// 0 → 1: how much of the route is drawn (draw-on before the trip starts).
  final double reveal;
  final Widget marker;
  final Size markerSize;
  final Color color;
  final Color doneColor;
  final double width;
  final bool rotateMarker;

  @override
  Widget build(BuildContext context) {
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (s, m) => s + m.length);
    Offset pos = Offset.zero;
    double angle = 0;
    if (metrics.isNotEmpty && total > 0) {
      var d = (total * progress.clamp(0.0, 1.0)).toDouble();
      for (final m in metrics) {
        if (d <= m.length || identical(m, metrics.last)) {
          final t = m.getTangentForOffset(d.clamp(0.0, m.length));
          if (t != null) {
            pos = t.position;
            angle = math.atan2(t.vector.dy, t.vector.dx);
          }
          break;
        }
        d -= m.length;
      }
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _RoutePainter(
                metrics: metrics,
                total: total,
                path: path,
                reveal: reveal,
                progress: progress,
                color: color,
                doneColor: doneColor,
                width: width,
              ),
            ),
          ),
        ),
        if (reveal >= 1)
          Positioned(
            left: pos.dx - markerSize.width / 2,
            top: pos.dy - markerSize.height / 2,
            width: markerSize.width,
            height: markerSize.height,
            child: Transform.rotate(angle: rotateMarker ? angle : 0, child: marker),
          ),
      ],
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.metrics,
    required this.total,
    required this.path,
    required this.reveal,
    required this.progress,
    required this.color,
    required this.doneColor,
    required this.width,
  });

  final List<PathMetric> metrics;
  final double total;
  final Path path;
  final double reveal;
  final double progress;
  final Color color;
  final Color doneColor;
  final double width;

  Path _sub(double from, double to) {
    final out = Path();
    var start = total * from;
    var end = total * to;
    for (final m in metrics) {
      if (end <= 0) break;
      final a = start.clamp(0.0, m.length);
      final b = end.clamp(0.0, m.length);
      if (b > a) out.addPath(m.extractPath(a, b), Offset.zero);
      start -= m.length;
      end -= m.length;
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final shown = _sub(0, reveal.clamp(0.0, 1.0));
    canvas.drawPath(shown, stroke(const Color(0xFFFFFFFF), width + 4));
    canvas.drawPath(shown, stroke(color, width));
    if (progress > 0) canvas.drawPath(_sub(0, progress.clamp(0.0, 1.0)), stroke(doneColor, width));
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.reveal != reveal || old.progress != progress || old.path != path || old.color != color;
}

/// Timed demo of [AppRouteFollow]: draws the route, then drives it.
/// Reports [onProgress] every frame and [onArrive] at the end.
/// Under reduced motion it jumps to the end.
class AppRouteTrip extends StatefulWidget {
  const AppRouteTrip({
    super.key,
    required this.path,
    required this.marker,
    this.markerSize = const Size(30, 18),
    this.tripDuration = const Duration(milliseconds: 2600),
    this.startDelay = const Duration(milliseconds: 1000),
    this.onProgress,
    this.onArrive,
  });

  final Path path;
  final Widget marker;
  final Size markerSize;
  final Duration tripDuration;
  final Duration startDelay;
  final ValueChanged<double>? onProgress;
  final VoidCallback? onArrive;

  @override
  State<AppRouteTrip> createState() => _AppRouteTripState();
}

class _AppRouteTripState extends State<AppRouteTrip> with TickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(vsync: this);
  late final AnimationController _trip = AnimationController(vsync: this);
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _reveal.value = 1;
      _trip.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onProgress?.call(1);
        widget.onArrive?.call();
      });
      return;
    }
    _trip.addListener(() => widget.onProgress?.call(_curved));
    _trip.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onArrive?.call();
    });
    _reveal.duration = const Duration(milliseconds: 700);
    _trip.duration = widget.tripDuration;
    _reveal.forward();
    _timer = Timer(widget.startDelay, () {
      if (mounted) _trip.forward();
    });
  }

  double get _curved => Curves.easeInOut.transform(_trip.value);

  @override
  void dispose() {
    _timer?.cancel();
    _reveal.dispose();
    _trip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_reveal, _trip]),
      builder: (context, _) => AppRouteFollow(
        path: widget.path,
        reveal: AppMotion.standard.transform(_reveal.value),
        progress: _curved,
        marker: widget.marker,
        markerSize: widget.markerSize,
      ),
    );
  }
}
