import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'app_motion.dart';

/// One-shot confetti burst from the centre of its box. Rare celebrations only:
/// first booking, all habits done, goal reached. Nothing under reduced motion.
/// Fills its parent: place it in a `Stack` under `Positioned.fill` (or any
/// bounded box) over the thing being celebrated.
class AppConfetti extends StatefulWidget {
  const AppConfetti({
    super.key,
    this.count = 26,
    this.colors = const [
      Color(0xFFE8402A),
      Color(0xFFFFB627),
      Color(0xFF3F9B5A),
      Color(0xFF1A73E8),
      Color(0xFFFF8A72),
    ],
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 1100),
    this.seed = 7,
  });

  final int count;
  final List<Color> colors;
  final Duration delay;
  final Duration duration;
  final int seed;

  @override
  State<AppConfetti> createState() => _AppConfettiState();
}

class _AppConfettiState extends State<AppConfetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final List<_Piece> _pieces = _make();
  Timer? _t;
  bool _started = false;
  bool _off = false;

  List<_Piece> _make() {
    final r = math.Random(widget.seed);
    return List.generate(widget.count, (i) {
      final a = r.nextDouble() * math.pi * 2;
      final d = 70 + r.nextDouble() * 60;
      return _Piece(
        dx: math.cos(a) * d,
        dy: math.sin(a) * d * 0.8 - 20,
        spin: (r.nextDouble() * 3 - 1.5) * math.pi,
        color: widget.colors[i % widget.colors.length],
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _off = true;
      return;
    }
    _t = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_off) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox.expand(child: CustomPaint(painter: _ConfettiPainter(_c, _pieces))),
      ),
    );
  }
}

class _Piece {
  _Piece({required this.dx, required this.dy, required this.spin, required this.color});
  final double dx, dy, spin;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.anim, this.pieces) : super(repaint: anim);
  final Animation<double> anim;
  final List<_Piece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    if (t <= 0 || t >= 1) return;
    final e = const Cubic(0.1, 0.8, 0.3, 1).transform(t);
    final c = size.center(Offset.zero);
    final fade = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
    final p = Paint();
    for (final piece in pieces) {
      canvas.save();
      canvas.translate(c.dx + piece.dx * e, c.dy + piece.dy * e + 40 * t * t);
      canvas.rotate(piece.spin * e);
      p.color = piece.color.withAlpha((255 * fade).round());
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -6, 8, 12), const Radius.circular(2)),
        p,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}

/// Small shapes (hearts, sparkles) that float up from the child and fade.
/// Reactions around a mascot or a "you did it" card. Short-lived by default
/// ([bursts] waves); never a permanent background. Off under reduced motion.
class AppFloaters extends StatefulWidget {
  const AppFloaters({
    super.key,
    required this.child,
    this.symbol = '♥',
    this.color = const Color(0xFFF08BA0),
    this.count = 5,
    this.bursts = 2,
    this.delay = Duration.zero,
  });

  final Widget child;
  final String symbol;
  final Color color;
  final int count;
  final int bursts;
  final Duration delay;

  @override
  State<AppFloaters> createState() => _AppFloatersState();
}

class _AppFloatersState extends State<AppFloaters> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  Timer? _t;
  int _runs = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) return;
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && ++_runs < widget.bursts) _c.forward(from: 0);
    });
    _t = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value;
                if (t == 0 || t == 1) return const SizedBox.shrink();
                return LayoutBuilder(
                  builder: (context, box) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < widget.count; i++)
                        _floater(i, t, box.biggest),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _floater(int i, double t, Size box) {
    final local = ((t - i * 0.12) / 0.7).clamp(0.0, 1.0);
    if (local <= 0 || local >= 1) return const SizedBox.shrink();
    final side = i.isEven ? 1 : -1;
    final x = box.width / 2 + side * (box.width * 0.30 + (i * 7 % 13)) + math.sin(local * 6) * 4;
    final y = box.height * 0.45 - local * box.height * 0.55;
    final o = local < 0.2 ? local / 0.2 : 1 - (local - 0.2) / 0.8;
    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: o.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.6 + 0.6 * local,
          child: Text(
            widget.symbol,
            style: TextStyle(color: widget.color, fontSize: 12 + (i % 3) * 3.0),
          ),
        ),
      ),
    );
  }
}
